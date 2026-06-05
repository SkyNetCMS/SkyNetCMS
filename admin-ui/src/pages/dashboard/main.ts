/**
 * SkyNetCMS Admin Dashboard
 * 
 * Initializes the service-injector library for the floating AI assistant window.
 */

import { ServiceInjector } from 'service-injector';
import { finder } from '@medv/finder';

/**
 * Custom styles for service-injector elements.
 * These override the library's default styles (e.g., #si-header default is gray #aaa).
 * Note: Styles for custom classes (.sn-toolbar-*) are in dashboard.css and work fine.
 */
const serviceInjectorStyles = `
    #si-tab {
        background: #1a1a2e;
        border: 1px solid #2a2a4a;
        border-right: none;
        border-radius: 8px 0 0 8px;
        box-shadow: -4px 0 12px rgba(0, 0, 0, 0.3);
        padding: 0;
    }
    #si-tab:hover {
        background: #16213e;
        border-color: #00d4ff;
    }
    #si-window {
        background: #1a1a2e;
        border: 1px solid #2a2a4a;
        border-radius: 12px;
        box-shadow: 0 16px 48px rgba(0, 0, 0, 0.5);
        overflow: hidden;
    }
    #si-inner {
        height: 100%;
        width: 100%;
        display: flex;
        flex-direction: column;
    }
    #si-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 8px 12px;
        background: #1a1a2e;
        border-bottom: 1px solid #2a2a4a;
        height: 44px;
        cursor: move;
        flex-shrink: 0;
    }
    #si-body {
        flex: 1;
        overflow: hidden;
        background: #0f0f1a;
        border: none;
    }
    #si-iframe {
        border: 0;
        width: 100%;
        height: 100%;
    }
    #si-shadow {
        background: #1a1a2e;
        border: 2px dashed #00d4ff;
        border-radius: 12px;
        opacity: 0.5;
    }
    .si-resize-corner {
        opacity: 0;
        background: transparent;
        transition: opacity 0.2s ease;
        width: 10px;
        height: 10px;
        border-radius: 2px;
    }
    #si-window:hover .si-resize-corner {
        opacity: 0.5;
        background: #3a3a5a;
    }
`;

// Declare global functions that service-injector exposes
declare global {
    interface Window {
        siOpenWindow: () => void;
        siToggleWindow: () => boolean;
        siRefreshMain: () => void;
        refreshMainPreview: (event?: MouseEvent) => void;
        selectElement: () => void;
        clearSelection: () => void;
        setViewMode: (mode: 'draft' | 'live') => void;
    }
    function siOpenWindow(): void;
    function siToggleWindow(): boolean;
    function siRefreshMain(): void;
}

// Store injector instance for later use
let injector: ServiceInjector | null = null;

// Track current view mode - default to draft for live editing experience
let currentMode: 'draft' | 'live' = 'draft';

// ---------------------------------------------------------------------------
// Element selection state (Phase 11: Visual Element Selection)
// ---------------------------------------------------------------------------

/** Minimal element descriptor sent to the AI (via the page-context backend). */
interface SelectedElement {
    label: number;          // visible badge number (#1, #2, ...)
    selector: string;       // "wise" minimal CSS selector (id > class > :nth-of-type)
    text: string;           // trimmed/truncated visible text (disambiguator)
    tag: string;            // lowercase tag name
}

/** One live entry in the selection set: the descriptor + its DOM node. */
interface SelectionEntry {
    el: Element;
    data: SelectedElement;
}

let selectMode = false;
let selectedEls: SelectionEntry[] = [];

// Tooltip messages for the toggle
const TOOLTIPS = {
    draft: "Viewing DRAFT - your work in progress. Click 'Live' to see the published site.",
    live: "Viewing LIVE - what visitors see. Click 'Draft' to continue editing."
};

/**
 * Initialize service-injector with configuration
 */
function initServiceInjector(): void {
    // Read custom templates from the DOM
    const tabTemplate = document.getElementById('si-tab-template')?.innerHTML;
    const windowTemplate = document.getElementById('si-window-template')?.innerHTML;

    injector = new ServiceInjector({
        wrapperMode: true,
        wrapperUrl: '/sn_admin/dev/',  // Default to draft mode for live editing
        url: '/sn_admin/oc/',
        position: 'right',
        offset: '50%',
        windowWidth: '520px',
        windowHeight: '75%',
        windowRight: '20px',
        windowTop: '20px',
        draggable: true,
        resizable: true,
        dockable: true,
        hideTab: true,
        tabTemplate: tabTemplate,
        windowTemplate: windowTemplate,
        styles: serviceInjectorStyles,
    });
    
    injector.install();

    // Track preview navigation: report page context to the backend on every
    // iframe load so the AI can query the user's current page (FR-052).
    const mainIframe = injector.getMainIframe();
    if (mainIframe) {
        mainIframe.addEventListener('load', () => {
            // Navigation invalidates captured DOM nodes: drop the selection set.
            // (selectedEls cleared without re-POST here; postPageContext below
            // sends the now-empty set together with the new page.)
            selectedEls = [];
            updateSelectionUI();
            // If select mode was active, re-arm it on the freshly loaded document.
            if (selectMode) {
                selectMode = false;
                enterSelectMode();
            }
            postPageContext();
        });
    }
}

/**
 * Push the current preview page context to the backend (AI page/URL awareness).
 *
 * Reads the main preview iframe's location/title (same-origin) plus the current
 * draft/live mode and POSTs them to /sn_admin/page-context. The OpenCode tool
 * `get_current_page` reads this back so the AI knows which page the user is on.
 *
 * Best-effort: silently ignores cross-origin/iframe-not-ready/network errors.
 */
function postPageContext(): void {
    if (!injector) return;

    const mainIframe = injector.getMainIframe();
    if (!mainIframe?.contentWindow) return;

    let path = '';
    let query = '';
    let title = '';
    try {
        const loc = mainIframe.contentWindow.location;
        path = loc.pathname;
        query = loc.search;
        // contentDocument is same-origin; guard in case it's not yet ready
        title = mainIframe.contentDocument?.title ?? '';
    } catch {
        // Cross-origin or not-ready: skip this update
        return;
    }

    void fetch('/sn_admin/page-context', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            path,
            query,
            title,
            mode: currentMode,
            selectedElements: selectedEls.map((e) => e.data),
        }),
    }).catch(() => {
        // Network/auth errors are non-fatal for the UI
    });
}

/**
 * Refresh the main website preview iframe
 * @param event - Optional mouse event to check for modifier keys
 * 
 * Default: Reload current page (preserves scroll position and state)
 * Ctrl+Click (Win/Linux) or Cmd+Click (Mac): Full reset to root URL (/)
 */
function refreshMainPreview(event?: MouseEvent): void {
    if (!injector) return;
    
    const mainIframe = injector.getMainIframe();
    
    // Ctrl+Click or Cmd+Click: Full reset to root
    if (event?.ctrlKey || event?.metaKey) {
        // Reset to root of current mode
        const rootUrl = currentMode === 'draft' ? '/sn_admin/dev/' : '/';
        injector.navigateMain(rootUrl);
        return;
    }
    
    // Default: Smart reload of current page
    if (mainIframe?.contentWindow) {
        try {
            mainIframe.contentWindow.location.reload();
        } catch {
            // Fallback if cross-origin (shouldn't happen for same-origin content)
            injector.refreshMain();
        }
    } else {
        injector.refreshMain();
    }
}

// ---------------------------------------------------------------------------
// Element selection (Phase 11)
//
// Runs entirely against the same-origin preview iframe. Hovering highlights the
// element under the cursor; clicking toggles it in/out of a curated set. Each
// selected element gets a persistent boundary box + a numbered corner badge
// (#1, #2, ...). The set is POSTed to the page-context backend on every change
// so the AI can read it via get_current_page. The set persists until cleared or
// the preview navigates / changes mode.
// ---------------------------------------------------------------------------

const OVERLAY_STYLE_ID = 'sn-select-style';
const OVERLAY_LAYER_ID = 'sn-select-overlay';
const HOVER_BOX_ID = 'sn-select-hover';

/** CSS injected into the preview document while select mode is active. */
const SELECT_OVERLAY_CSS = `
#${OVERLAY_LAYER_ID} { position: absolute; top: 0; left: 0; width: 0; height: 0; z-index: 2147483646; pointer-events: none; }
.sn-sel-box { position: absolute; box-sizing: border-box; border: 2px solid #00d4ff; background: rgba(0,212,255,0.08); pointer-events: none; }
.sn-sel-badge { position: absolute; top: -1px; left: -1px; transform: translateY(-100%); background: #00d4ff; color: #001018; font: 600 11px/1.4 system-ui, sans-serif; padding: 1px 6px; border-radius: 4px 4px 4px 0; white-space: nowrap; }
#${HOVER_BOX_ID} { position: absolute; box-sizing: border-box; border: 2px dashed #00d4ff; background: rgba(0,212,255,0.04); pointer-events: none; z-index: 2147483645; }
html.sn-selecting, html.sn-selecting * { cursor: crosshair !important; }
`;

/** The preview iframe's document, or null if not ready/same-origin. */
function previewDoc(): Document | null {
    const iframe = injector?.getMainIframe();
    try {
        return iframe?.contentDocument ?? null;
    } catch {
        return null;
    }
}

/** Trim + collapse whitespace and truncate visible text for the descriptor. */
function elementText(el: Element): string {
    const t = (el.textContent ?? '').replace(/\s+/g, ' ').trim();
    return t.length > 100 ? t.slice(0, 100) + '…' : t;
}

/** Build the minimal descriptor for an element using a wise selector. */
function describeElement(el: Element, label: number): SelectedElement {
    let selector = '';
    try {
        selector = finder(el, {
            // Prefer meaningful ids/classes; fall back to :nth-of-type only when needed.
            seedMinLength: 1,
            optimizedMinLength: 2,
        });
    } catch {
        selector = el.tagName.toLowerCase();
    }
    return {
        label,
        selector,
        text: elementText(el),
        tag: el.tagName.toLowerCase(),
    };
}

/** Is this element part of our own overlay (should be ignored for selection)? */
function isOverlayNode(el: Element | null): boolean {
    if (!el) return true;
    const id = (el as HTMLElement).id;
    if (id === OVERLAY_LAYER_ID || id === HOVER_BOX_ID) return true;
    return !!el.closest(`#${OVERLAY_LAYER_ID}`);
}

/** Reposition all selection boxes + the hover box to match current layout. */
function repositionOverlay(): void {
    const doc = previewDoc();
    if (!doc) return;
    const layer = doc.getElementById(OVERLAY_LAYER_ID);
    if (!layer) return;

    // Rebuild selection boxes from the live set.
    layer.innerHTML = '';
    selectedEls.forEach((entry) => {
        const r = entry.el.getBoundingClientRect();
        const scrollX = doc.defaultView?.scrollX ?? 0;
        const scrollY = doc.defaultView?.scrollY ?? 0;
        const box = doc.createElement('div');
        box.className = 'sn-sel-box';
        box.style.left = `${r.left + scrollX}px`;
        box.style.top = `${r.top + scrollY}px`;
        box.style.width = `${r.width}px`;
        box.style.height = `${r.height}px`;
        const badge = doc.createElement('div');
        badge.className = 'sn-sel-badge';
        badge.textContent = `#${entry.data.label}`;
        box.appendChild(badge);
        layer.appendChild(box);
    });
}

let repositionScheduled = false;
function scheduleReposition(): void {
    if (repositionScheduled) return;
    repositionScheduled = true;
    requestAnimationFrame(() => {
        repositionScheduled = false;
        repositionOverlay();
    });
}

function onPreviewHover(ev: Event): void {
    const doc = previewDoc();
    if (!doc) return;
    const target = ev.target as Element | null;
    const hover = doc.getElementById(HOVER_BOX_ID) as HTMLElement | null;
    if (!hover || !target || isOverlayNode(target)) {
        if (hover) hover.style.display = 'none';
        return;
    }
    const r = target.getBoundingClientRect();
    const scrollX = doc.defaultView?.scrollX ?? 0;
    const scrollY = doc.defaultView?.scrollY ?? 0;
    hover.style.display = 'block';
    hover.style.left = `${r.left + scrollX}px`;
    hover.style.top = `${r.top + scrollY}px`;
    hover.style.width = `${r.width}px`;
    hover.style.height = `${r.height}px`;
}

function onPreviewClick(ev: MouseEvent): void {
    if (!selectMode) return;
    const target = ev.target as Element | null;
    if (!target || isOverlayNode(target)) return;
    // Prevent the click from navigating/activating the previewed site.
    ev.preventDefault();
    ev.stopPropagation();

    const existing = selectedEls.findIndex((e) => e.el === target);
    if (existing >= 0) {
        // Toggle off and renumber the rest.
        selectedEls.splice(existing, 1);
        selectedEls.forEach((e, i) => (e.data.label = i + 1));
    } else {
        const label = selectedEls.length + 1;
        selectedEls.push({ el: target, data: describeElement(target, label) });
    }
    repositionOverlay();
    updateSelectionUI();
    postPageContext();
}

function onPreviewScrollOrResize(): void {
    scheduleReposition();
}

/** Attach selection listeners + overlay into the preview document. */
function enterSelectMode(): void {
    const doc = previewDoc();
    if (!doc) return;
    selectMode = true;

    // Inject styles.
    if (!doc.getElementById(OVERLAY_STYLE_ID)) {
        const style = doc.createElement('style');
        style.id = OVERLAY_STYLE_ID;
        style.textContent = SELECT_OVERLAY_CSS;
        doc.head.appendChild(style);
    }
    // Overlay layer + hover box.
    if (!doc.getElementById(OVERLAY_LAYER_ID)) {
        const layer = doc.createElement('div');
        layer.id = OVERLAY_LAYER_ID;
        doc.body.appendChild(layer);
    }
    if (!doc.getElementById(HOVER_BOX_ID)) {
        const hover = doc.createElement('div');
        hover.id = HOVER_BOX_ID;
        hover.style.display = 'none';
        doc.body.appendChild(hover);
    }
    doc.documentElement.classList.add('sn-selecting');

    doc.addEventListener('mousemove', onPreviewHover, true);
    doc.addEventListener('click', onPreviewClick, true);
    doc.defaultView?.addEventListener('scroll', onPreviewScrollOrResize, true);
    doc.defaultView?.addEventListener('resize', onPreviewScrollOrResize, true);
    doc.addEventListener('keydown', onSelectKeydown, true);

    repositionOverlay();
    updateSelectionUI();
}

/** Remove listeners + overlay (keeps the captured set unless asked to clear). */
function exitSelectMode(): void {
    selectMode = false;
    const doc = previewDoc();
    if (doc) {
        doc.removeEventListener('mousemove', onPreviewHover, true);
        doc.removeEventListener('click', onPreviewClick, true);
        doc.defaultView?.removeEventListener('scroll', onPreviewScrollOrResize, true);
        doc.defaultView?.removeEventListener('resize', onPreviewScrollOrResize, true);
        doc.removeEventListener('keydown', onSelectKeydown, true);
        doc.documentElement.classList.remove('sn-selecting');
        doc.getElementById(OVERLAY_STYLE_ID)?.remove();
        doc.getElementById(OVERLAY_LAYER_ID)?.remove();
        doc.getElementById(HOVER_BOX_ID)?.remove();
    }
    updateSelectionUI();
}

function onSelectKeydown(ev: KeyboardEvent): void {
    if (ev.key === 'Escape') {
        clearSelection();
        toggleSelectButton(false);
        exitSelectMode();
    }
}

/**
 * Toolbar "Select" button handler: toggle element selection mode.
 * Exiting select mode keeps the current selection (so the user can ask the AI
 * about it); use "Clear" to empty the set.
 */
function selectElement(): void {
    if (!injector) return;
    if (selectMode) {
        toggleSelectButton(false);
        exitSelectMode();
    } else {
        toggleSelectButton(true);
        enterSelectMode();
    }
}

/** Clear the whole selection set and refresh overlay + backend. */
function clearSelection(): void {
    selectedEls = [];
    repositionOverlay();
    updateSelectionUI();
    postPageContext();
}

/** Reflect select-mode active state on the toolbar button. */
function toggleSelectButton(active: boolean): void {
    const btn = document.querySelector('.sn-toolbar-btn[data-action="select"]');
    if (btn) btn.classList.toggle('active', active);
}

/** Update the toolbar selection count + Clear control. */
function updateSelectionUI(): void {
    const counter = document.querySelector('.sn-select-count');
    const clearBtn = document.querySelector('.sn-select-clear');
    const count = selectedEls.length;
    if (counter) {
        counter.textContent = count > 0 ? `${count} selected` : '';
        (counter as HTMLElement).style.display = count > 0 ? '' : 'none';
    }
    if (clearBtn) {
        (clearBtn as HTMLElement).style.display = count > 0 ? '' : 'none';
    }
}

/**
 * Set the view mode (draft or live)
 * 
 * Draft mode shows the Vite dev server with hot module replacement (HMR)
 * running in the active worktree - your work in progress.
 * 
 * Live mode shows the production site at / - what visitors see.
 * 
 * @param mode - 'draft' or 'live'
 */
function setViewMode(mode: 'draft' | 'live'): void {
    if (!injector || mode === currentMode) return;
    
    currentMode = mode;
    
    // Navigate to appropriate URL
    if (mode === 'draft') {
        injector.navigateMain('/sn_admin/dev/');
    } else {
        injector.navigateMain('/');
    }
    
    // Update toggle UI - need to wait for service-injector's DOM
    updateToggleUI();

    // Report the mode switch immediately; the iframe 'load' handler will
    // refine path/title once the new page finishes loading.
    postPageContext();
}

/**
 * Update the toggle UI to reflect current mode
 */
function updateToggleUI(): void {
    const toggle = document.querySelector('.sn-view-toggle');
    const draftBtn = document.querySelector('.sn-toggle-option[data-mode="draft"]');
    const liveBtn = document.querySelector('.sn-toggle-option[data-mode="live"]');
    
    if (!toggle || !draftBtn || !liveBtn) return;
    
    // Update active states
    if (currentMode === 'draft') {
        draftBtn.classList.add('active');
        liveBtn.classList.remove('active');
    } else {
        draftBtn.classList.remove('active');
        liveBtn.classList.add('active');
    }
    
    // Update tooltip
    toggle.setAttribute('title', TOOLTIPS[currentMode]);
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    initServiceInjector();
    
    // Set initial toggle state on load (matches default currentMode = 'draft')
    // Use setTimeout to ensure service-injector has injected the DOM
    setTimeout(() => {
        updateToggleUI();
        updateSelectionUI();
    }, 100);
});

// Expose functions globally for toolbar buttons (onclick handlers in HTML templates)
window.refreshMainPreview = refreshMainPreview;
window.selectElement = selectElement;
window.clearSelection = clearSelection;
window.setViewMode = setViewMode;
