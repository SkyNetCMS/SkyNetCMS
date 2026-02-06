/**
 * SkyNetCMS Admin Dashboard
 * 
 * Initializes the service-injector library for the floating AI assistant window.
 */

import { ServiceInjector } from 'service-injector';

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

/**
 * Placeholder for future element selector feature
 */
function selectElement(): void {
    // Future phase: Allow user to click on an element in the preview
    // and provide that context to the AI
    console.log('Element selector - coming in future phase');
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
    }, 100);
});

// Expose functions globally for toolbar buttons (onclick handlers in HTML templates)
window.refreshMainPreview = refreshMainPreview;
window.selectElement = selectElement;
window.setViewMode = setViewMode;
