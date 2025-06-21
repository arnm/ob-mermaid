;;; test-init.el --- Minimal Emacs configuration for testing ob-mermaid

;;; Commentary:
;; This file provides a minimal Emacs configuration specifically for testing
;; the ob-mermaid package. It loads only the necessary components.


;; Disable package.el to avoid conflicts with local development
(setq package-enable-at-startup nil)

;; Add current directory to load path for local development
(add-to-list 'load-path default-directory)

;; Load required dependencies first
(require 'org)
(require 'ob)
(require 'ob-eval)
(require 'ob-mermaid)

;; Set up mermaid CLI path (should be available in PATH via nix)
(setq ob-mermaid-cli-path "mmdc")

;; Enable mermaid in org-babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (mermaid . t)))

;; Don't ask for confirmation when evaluating code blocks (for testing)
(setq org-confirm-babel-evaluate nil)

;; Basic org-mode settings
(setq org-startup-folded nil)
(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)

;; Display settings for better testing experience
(setq inhibit-startup-message t)
(setq initial-scratch-message
      ";; ob-mermaid test environment loaded
;; Open test-example.org to test mermaid diagrams
;; Use C-c C-c on a mermaid code block to execute it
")

;; Enable visual-line-mode for better org experience
(add-hook 'org-mode-hook 'visual-line-mode)

;; Show which ob-mermaid file was loaded for verification
(message "✓ Loaded ob-mermaid from: %s" (locate-library "ob-mermaid"))
;; Message to confirm loading
(message "✓ ob-mermaid test environment loaded successfully!")
(message "✓ Mermaid CLI path: %s" ob-mermaid-cli-path)

;;; test-init.el ends here
