
(require 'ob)
(require 'ob-eval)

(defvar org-babel-default-header-args:mermaid
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluatiing a mermaid source block.")

(defcustom org-mermaid-path nil
  "Path to mermaid.cli executable."
  :group 'org-babel
  :type 'string)

(defun org-babel-execute:mermaid (body params)
  (let* ((out-file (or (cdr (assoc :file params))
                       (error "mermaid requires a \":file\" header argument")))
         (temp-file (org-babel-temp-file "mermaid-"))
         (cmd (if (not org-mermaid-path)
                  (error "`org-mermaid-path' is not set")
                (concat (shell-quote-argument (expand-file-name org-mermaid-path))
                        " -i " (org-babel-process-file-name temp-file)
                        " -o " (org-babel-process-file-name out-file)))))
    (unless (file-exists-p org-mermaid-path)
      (error "could not find mermaid.cli executable at %s" org-mermaid-path))
    (with-temp-file temp-file (insert body))
    (message "%s" cmd)
    (org-babel-eval cmd "")
    nil))

(provide 'ob-mermaid)
