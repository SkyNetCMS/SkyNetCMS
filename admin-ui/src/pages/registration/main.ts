/**
 * SkyNetCMS Admin Registration
 * 
 * Handles the one-time admin account setup form.
 */

interface FormElements {
    form: HTMLFormElement;
    errorMessage: HTMLElement;
    successMessage: HTMLElement;
    submitBtn: HTMLButtonElement;
    usernameInput: HTMLInputElement;
    passwordInput: HTMLInputElement;
    confirmPasswordInput: HTMLInputElement;
}

interface RegistrationResponse {
    success: boolean;
    error?: string;
}

/**
 * Get all form elements with type safety
 */
function getFormElements(): FormElements {
    return {
        form: document.getElementById('registerForm') as HTMLFormElement,
        errorMessage: document.getElementById('errorMessage') as HTMLElement,
        successMessage: document.getElementById('successMessage') as HTMLElement,
        submitBtn: document.getElementById('submitBtn') as HTMLButtonElement,
        usernameInput: document.getElementById('username') as HTMLInputElement,
        passwordInput: document.getElementById('password') as HTMLInputElement,
        confirmPasswordInput: document.getElementById('confirmPassword') as HTMLInputElement,
    };
}

/**
 * Show error message
 */
function showError(elements: FormElements, message: string): void {
    elements.errorMessage.textContent = message;
    elements.errorMessage.classList.add('visible');
    elements.successMessage.classList.remove('visible');
}

/**
 * Show success message
 */
function showSuccess(elements: FormElements, message: string): void {
    elements.successMessage.textContent = message;
    elements.successMessage.classList.add('visible');
    elements.errorMessage.classList.remove('visible');
}

/**
 * Hide all messages
 */
function hideMessages(elements: FormElements): void {
    elements.errorMessage.classList.remove('visible');
    elements.successMessage.classList.remove('visible');
}

/**
 * Clear field error styles
 */
function clearFieldErrors(elements: FormElements): void {
    elements.usernameInput.classList.remove('error');
    elements.passwordInput.classList.remove('error');
    elements.confirmPasswordInput.classList.remove('error');
}

/**
 * Validate the registration form
 */
function validateForm(elements: FormElements): boolean {
    clearFieldErrors(elements);
    
    const username = elements.usernameInput.value.trim();
    const password = elements.passwordInput.value;
    const confirmPassword = elements.confirmPasswordInput.value;

    if (!username) {
        elements.usernameInput.classList.add('error');
        showError(elements, 'Username is required');
        return false;
    }

    if (username.length < 3) {
        elements.usernameInput.classList.add('error');
        showError(elements, 'Username must be at least 3 characters');
        return false;
    }

    if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
        elements.usernameInput.classList.add('error');
        showError(elements, 'Username can only contain letters, numbers, underscores, and hyphens');
        return false;
    }

    if (!password) {
        elements.passwordInput.classList.add('error');
        showError(elements, 'Password is required');
        return false;
    }

    if (password.length < 8) {
        elements.passwordInput.classList.add('error');
        showError(elements, 'Password must be at least 8 characters');
        return false;
    }

    if (password !== confirmPassword) {
        elements.confirmPasswordInput.classList.add('error');
        showError(elements, 'Passwords do not match');
        return false;
    }

    return true;
}

/**
 * Handle form submission
 */
async function handleSubmit(e: Event, elements: FormElements): Promise<void> {
    e.preventDefault();
    hideMessages(elements);

    if (!validateForm(elements)) {
        return;
    }

    elements.submitBtn.disabled = true;
    elements.submitBtn.textContent = 'Creating account...';

    try {
        const formData = new URLSearchParams();
        formData.append('username', elements.usernameInput.value.trim());
        formData.append('password', elements.passwordInput.value);
        formData.append('confirmPassword', elements.confirmPasswordInput.value);

        const response = await fetch('/sn_admin/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: formData.toString()
        });

        const data: RegistrationResponse = await response.json();

        if (data.success) {
            showSuccess(elements, 'Account created successfully! Redirecting...');
            setTimeout(() => {
                window.location.href = '/sn_admin/';
            }, 1500);
        } else {
            showError(elements, data.error || 'Registration failed. Please try again.');
            elements.submitBtn.disabled = false;
            elements.submitBtn.textContent = 'Create Admin Account';
        }
    } catch {
        showError(elements, 'An error occurred. Please try again.');
        elements.submitBtn.disabled = false;
        elements.submitBtn.textContent = 'Create Admin Account';
    }
}

/**
 * Setup real-time validation
 */
function setupRealtimeValidation(elements: FormElements): void {
    // Password match validation
    elements.confirmPasswordInput.addEventListener('input', function() {
        if (this.value && this.value !== elements.passwordInput.value) {
            this.classList.add('error');
        } else {
            this.classList.remove('error');
        }
    });

    // Password length validation
    elements.passwordInput.addEventListener('input', function() {
        if (this.value && this.value.length < 8) {
            this.classList.add('error');
        } else {
            this.classList.remove('error');
        }
        // Also check confirm field
        if (elements.confirmPasswordInput.value && elements.confirmPasswordInput.value !== this.value) {
            elements.confirmPasswordInput.classList.add('error');
        } else {
            elements.confirmPasswordInput.classList.remove('error');
        }
    });
}

/**
 * Initialize the registration form
 */
function init(): void {
    const elements = getFormElements();
    
    elements.form.addEventListener('submit', (e) => handleSubmit(e, elements));
    setupRealtimeValidation(elements);
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', init);
