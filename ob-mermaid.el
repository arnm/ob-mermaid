;;; ob-mermaid.el --- org-babel support for mermaid evaluation

;; Copyright (C) 2018 Alexei Nunez

;; Author: Alexei Nunez <alexeirnunez@gmail.com>
;; URL: https://github.com/arnm/ob-mermaid
;; Keywords: lisp
;; Version: 0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating mermaid diagrams.

;;; Requirements:

;; mermaid.cli | https://github.com/mermaidjs/mermaid.cli

;;; Code:
(require 'ob)
(require 'ob-eval)

(defvar org-babel-default-header-args:mermaid
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluatiing a mermaid source block.")

(defcustom ob-mermaid-cli-path nil
  "Path to mermaid.cli executable."
  :group 'org-babel
  :type 'string)

(defcustom ob-mermaid-sandbox-wordaround nil
  "An option to toggle workaround of Linux kernal sandbox issue."
  :type 'boolean
  :safe #'booleanp
  :group 'org-babel)

(defun org-babel-execute:mermaid (body params)
  (let* ((out-file (or (cdr (assoc :file params))
                       (error "mermaid requires a \":file\" header argument")))
         (temp-file (org-babel-temp-file "mermaid-"))
         (cmd (if (not ob-mermaid-cli-path)
                  (error "`ob-mermaid-cli-path' is not set")
                (concat (shell-quote-argument (expand-file-name ob-mermaid-cli-path))
                        (if ob-mermaid-sandbox-wordaround
                            " -p ~/.puppeteer-config.json "
                          "")
                        " -i " (org-babel-process-file-name temp-file)
                        " -o " (org-babel-process-file-name out-file)))))
    (unless (file-exists-p ob-mermaid-cli-path)
      (error "could not find mermaid.cli executable at %s" ob-mermaid-cli-path))
    (with-temp-file temp-file (insert body))
    (message "%s" cmd)
    (org-babel-eval cmd "")
    nil))

(provide 'ob-mermaid)


;;; ob-mermaid.el ends here
