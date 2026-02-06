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
        refreshMainPreview: () => void;
        selectElement: () => void;
        toggleDevMode: (event?: Event) => void;
    }
    function siOpenWindow(): void;
    function siToggleWindow(): boolean;
    function siRefreshMain(): void;
}

// Store injector instance for later use
let injector: ServiceInjector | null = null;

// Track dev mode state - default to dev mode for live editing experience
let devMode = true;

/**
 * Initialize service-injector with configuration
 */
function initServiceInjector(): void {
    // Read custom templates from the DOM
    const tabTemplate = document.getElementById('si-tab-template')?.innerHTML;
    const windowTemplate = document.getElementById('si-window-template')?.innerHTML;

    injector = new ServiceInjector({
        wrapperMode: true,
        wrapperUrl: '/sn_admin/dev/',  // Default to dev mode for live editing
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
        injector.navigateMain('/');
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
 * Toggle between production (/) and dev server (/sn_admin/dev/) preview
 * 
 * Dev mode shows the Vite dev server with hot module replacement (HMR).
 * The dev server starts on-demand when first accessed and auto-shuts down
 * after 5 minutes of inactivity.
 * 
 * @param event - Optional event from onclick handler to get button reference
 */
function toggleDevMode(event?: Event): void {
    if (!injector) return;
    
    // Get button from event or fallback to querySelector (service-injector injects DOM dynamically)
    const btn = (event?.currentTarget as HTMLElement) || document.querySelector('.sn-dev-toggle');
    
    if (devMode) {
        // Switch back to production
        devMode = false;
        injector.navigateMain('/');
        btn?.classList.remove('active');
    } else {
        // Switch to dev mode
        devMode = true;
        // Navigate to dev server - it will start automatically if not running
        injector.navigateMain('/sn_admin/dev/');
        btn?.classList.add('active');
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    initServiceInjector();
    
    // Set Dev button active state on load (matches default devMode = true)
    // Use setTimeout to ensure service-injector has injected the DOM
    setTimeout(() => {
        const devBtn = document.querySelector('.sn-dev-toggle');
        devBtn?.classList.add('active');
    }, 100);
});

// Expose functions globally for toolbar buttons (onclick handlers in HTML templates)
window.refreshMainPreview = refreshMainPreview;
window.selectElement = selectElement;
window.toggleDevMode = toggleDevMode;
