;;; scholar-import.el --- Import Bibtex & PDF from Google Scholar -*- lexical-binding: t -*-

;; Author: Anh T Nguyen <https://github.com/teeann>
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (org "9.0") (request "0.3.2") (s "1.10.0"))
;; Homepage: https://github.com/teeann/scholar-import

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package lets you import Bibtex & PDF files from Google Scholar
;; via org-protocol and Web extension Scholar-to-Emacs.

;;; Code:

(require 'org-protocol)
(require 'request)

(defgroup scholar-import nil
  "Emacs package to import Bibtex & PDF from Google Scholar."
  :group 'tools)

(defcustom scholar-import-bibliography nil
  "Bibliography file to import Bibtex into."
  :type 'string
  :group 'scholar-import)

(defcustom scholar-import-library-path nil
  "Directory to store downloaded PDFs."
  :type 'string
  :group 'scholar-import)

(defcustom scholar-import-before-hook nil
  "A hook to run before importing new entry."
  :group 'scholar-import
  :type 'hook)

(defcustom scholar-import-after-hook nil
  "A hook to run after importing new entry."
  :group 'scholar-import
  :type 'hook)

(defcustom scholar-import-user-process-function nil
  "A hook to run after importing new entry."
  :group 'scholar-import
  :type 'function)

(defun scholar-import-add-entry (info)
  "Import data from Google Scholar via org-protocol URL INFO."
  (let ((bibtexUrl (url-unhex-string (plist-get info :bibtexUrl)))
        (pdfUrl (plist-get info :pdfUrl)))
    (request
      bibtexUrl
      :parser #'buffer-string
      ;; Google seems to block requests without a normal User-Agent
      :headers '(("User-Agent" . "Mozilla/5.0 (X11; Linux x86_64; rv:99.0) Gecko/20100101 Firefox/99.0"))
      :success (cl-function
                (lambda (&key data &allow-other-keys)
                  (scholar-import--add-bibtex-pdf data pdfUrl))))))

(defun scholar-import--add-bibtex-pdf (bibtex pdfUrl)
  "Add a BIBTEX entry and download document from PDFURL."
  (let* ((key (cadr (s-match "[^{]+{\\([^,]+\\)" bibtex)))
         (dest (concat (file-name-as-directory scholar-import-library-path) key ".pdf")))
    (run-hooks 'scholar-import-before-hook)
    (scholar-import--append-file bibtex scholar-import-bibliography)
    ;; TODO download documents asynchronously
    (url-copy-file pdfUrl dest)
    (if (functionp scholar-import-user-process-function)
        (funcall scholar-import-user-process-function key pdfUrl))
    (run-hooks 'scholar-import-after-hook)))

(defun scholar-import--append-file (text file)
  "Append TEXT to the end of a given FILE."
  (save-excursion
    (with-temp-buffer
      (insert-file file)
      (goto-char (point-max))
      (insert text)
      (write-file file))))

(push '("gscholar" :protocol "gscholar" :function scholar-import-add-entry)
      org-protocol-protocol-alist)

(provide 'scholar-import)
;;; scholar-import.el ends here
