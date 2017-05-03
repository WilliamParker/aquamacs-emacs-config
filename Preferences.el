;; This is the Aquamacs Preferences file.
;; Add Emacs-Lisp code here that should be executed whenever
;; you start Aquamacs Emacs. If errors occur, Aquamacs will stop
;; evaluating this file and print errors in the *Messags* buffer.
;; Use this file in place of ~/.emacs (which is loaded as well.)

;; This is the Aquamacs Preferences file.
;; Add Emacs-Lisp code here that should be executed whenever
;; you start Aquamacs Emacs. If errors occur, Aquamacs will stop
;; evaluating this file and print errors in the *Messags* buffer.
;; Use this file in place of ~/.emacs (which is loaded as well.)

(add-to-list 'custom-theme-load-path "~/emacs_packages")

(add-to-list 'load-path "~/git/emacs-libraries")

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(package-refresh-contents)

(defun install-if-absent (user-package)
       (when (not (package-installed-p user-package))
             (package-install user-package)))

(defconst my-packages '(auctex clojure-mode neotree rainbow-delimiters
                        smooth-scrolling atom-one-dark-theme cider
                        god-mode elpy helm git-timemachine color-theme-modern
                        projectile helm-projectile browse-kill-ring company company-flx markdown-mode
                        enh-ruby-mode helm-ag))

;; Packages used in past: jdee clj-refactor cljr-helm excorporate calfw

(dolist (to-install my-packages)
        (install-if-absent to-install))

(require 'rainbow-delimiters)

;;;; Linum setup
(global-linum-mode t)

;; See http://stackoverflow.com/questions/9304192/emacs-linum-mode-and-size-of-font-unreadable-line-numbers
(eval-after-load "linum"
  '(set-face-attribute 'linum nil :height 100))


;;;; Miscellaneous setup

(require 'smooth-scrolling)
(require 'neotree)
(setq neo-window-width 90)
(setq Buffer-menu-name-width 40)
(set-face-attribute 'minibuffer nil :height 200)

;;;; Coloring setup

(add-to-list 'custom-theme-load-path "~/emacs_packages")

(setq my-themes '(charcoal-black atom-one-dark))

(setq my-cur-theme nil)
(defun cycle-my-theme ()
  "Cycle through a list of themes, my-themes"
  (interactive)
  (when my-cur-theme
    (disable-theme my-cur-theme)
    (setq my-themes (append my-themes (list my-cur-theme))))
  (setq my-cur-theme (pop my-themes))
  (load-theme my-cur-theme t)
  ;; Adding this at init time and as a hook failed for some reason.  I find the coloring for
  ;; this face in Elpy annoying.  TODO: Change this to only occur when atom-one-dark is used.
  (set-face-attribute 'font-lock-variable-name-face nil :foreground nil :inherit 'default))

;;;; Markdown preview setup
;; This obviously requires that Markdown be installed.  I used the command
;; "brew install markdown".
(custom-set-variables '(markdown-command "/usr/local/bin/markdown"))
;; Set this globally for the time being since this is my only use-case for
;; web browsing in Emacs at this time.
(setq browse-url-browser-function 'eww-browse-url)

;;;; Company-mode setup

;; Wait 1.2 seconds before offering autocompletion
(setq company-idle-delay 1.2)

(add-hook 'cider-repl-mode-hook #'company-mode)
(add-hook 'cider-mode-hook #'company-mode)

(with-eval-after-load 'company
  (company-flx-mode +1))

;;;; Paredit setup
(setq paredit-numpad-navigate nil)
(defun paredit-numpad-navigate-toggle ()
    (interactive)
    (if paredit-numpad-navigate
        (progn
          (setq paredit-numpad-navigate nil)
          (disable-paredit-mode))
        (progn
          (setq paredit-numpad-navigate t)
          ;; Note that these will be bindings for all buffers in the same major mode.
          ;; This satisfies most use-cases but ideally these bindings would be local to
          ;; a single buffer and could be turned off.
          (local-set-key (kbd "<kp-6>") 'paredit-forward)
          (local-set-key (kbd "<kp-4>") 'paredit-backward)
          (local-set-key (kbd "<kp-3>") 'paredit-forward-down)
          (local-set-key (kbd "<kp-9>") 'paredit-forward-up)
          (local-set-key (kbd "<kp-7>") 'paredit-backward-up)
          (local-set-key (kbd "<kp-1>") 'paredit-backward-down))))

(global-set-key (kbd "<kp-0>") 'paredit-numpad-navigate-toggle)

;;;; Initialize Ruby environment

(add-to-list 'auto-mode-alist '("\\.rb$" . enh-ruby-mode))
(add-hook 'enh-ruby-mode-hook 'robe-mode)

(eval-after-load 'company
  '(push 'company-robe company-backends))

;; TODO: Commit RVM.el into source control and/or figure out a way to directly retrieve it from GitHub
(require 'rvm)
;(rvm-use-default)


;;;; Initialize Clojure environment

(add-to-list 'auto-mode-alist '("\\.cljc\\'" . clojure-mode))
(add-hook 'clojure-mode-hook 'rainbow-delimiters-mode)
(setq cider-repl-use-clojure-font-lock t)
(setq cider-repl-use-pretty-printing t)
(setq cider-auto-select-error-buffer nil)
(setq cider-show-error-buffer nil)

(add-hook 'clojure-mode-hook
          (lambda ()
           (font-lock-add-keywords nil
            '(("\\<\\(FIXME\\):" 1
               font-lock-warning-face t)))))

(require 'helm-config)
(require 'helm)
(require 'helm-utils)

(defun helm-clojure-headlines ()
  "Display headlines for the current Clojure file."
  (interactive)
  (setq helm-current-buffer (current-buffer)) ;; Fixes bug where the current buffer sometimes isn't used
  (jit-lock-fontify-now) ;; https://groups.google.com/forum/#!topic/emacs-helm/YwqsyRRHjY4
  (helm :sources
    (helm-build-in-buffer-source "Clojure Headlines"
                                 :data (with-helm-current-buffer
                                 (goto-char (point-min))
                                 (cl-loop while (re-search-forward "^(.*[a-zA-Z]+" nil t)
                                          for line = (buffer-substring (point-at-bol) (point-at-eol))
                                          for pos = (line-number-at-pos)
                                          collect (propertize line 'helm-realvalue pos)))
                                 :get-line 'buffer-substring
                                 :action (lambda (c) (helm-goto-line c)))
                                 :buffer "helm-clojure-headlines"))

(require 'cljr-helm)

;;;; Initialize LaTeX environment

;; Scale up default AucTex math preview size
(set-default 'preview-scale-function 6.5)


;;;; Initialize Python environment

(setq elpy-rpc-python-command "/usr/local/bin/python3")

;; TODO: Change this to just remove modules instead of setting the entire list.
(setq elpy-modules '(elpy-module-sane-defaults
                     elpy-module-company
                     elpy-module-eldoc
                     ;elpy-module-highlight-indentation
                     elpy-module-pyvenv
                     elpy-module-yasnippet))

(elpy-enable)

;;;; Custom keybindings
(global-set-key (kbd "C-d") 'forward-word)
(global-set-key (kbd "C-s") 'backward-word)

(require 'tabbar)
(global-set-key (kbd "C-c u") 'tabbar-backward-tab)
(global-set-key (kbd "C-c i") 'tabbar-forward-tab)

;; Escape is actually bound to caps lock on my machine
(global-set-key (kbd "<escape>") 'god-mode-all)

(global-set-key [f4] 'helm-projectile-ag)
(global-set-key [f5] 'company-complete)
(global-set-key [f6] 'cycle-my-theme)
(global-set-key [f7] 'helm-clojure-headlines)
(global-set-key [f8] 'neotree-toggle)
(global-set-key [f9] 'git-timemachine-toggle)
(global-set-key [f10] 'helm-buffers-list)
(global-set-key [f11] 'helm-projectile)
(global-set-key [f12] 'helm-projectile-switch-project)
(global-set-key (kbd "M-x") 'helm-M-x)
