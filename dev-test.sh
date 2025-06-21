#!/usr/bin/env bash
# dev-test.sh - Development testing script for ob-mermaid

set -e

echo "🔧 ob-mermaid Development Test Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    if ! command -v mmdc &> /dev/null; then
        print_error "mermaid-cli (mmdc) not found in PATH"
        echo "Make sure you're in the nix devenv: 'nix develop'"
        exit 1
    fi
    print_status "mermaid-cli found: $(which mmdc)"

    if ! command -v emacs &> /dev/null; then
        print_error "Emacs not found in PATH"
        exit 1
    fi
    print_status "Emacs found: $(emacs --version | head -n1)"

    if [ ! -f "ob-mermaid.el" ]; then
        print_error "ob-mermaid.el not found in current directory"
        exit 1
    fi
    print_status "Local ob-mermaid.el found"
}

# Clean previous test outputs
clean_outputs() {
    echo "Cleaning previous test outputs..."
    rm -f test*.png test*.svg test*.pdf *~
    rm -f \#*\#
    print_status "Cleaned output files"
}

# Test mermaid CLI
test_mermaid_cli() {
    echo "Testing mermaid CLI..."
    mmdc --version
    print_status "Mermaid CLI is working"
}

# Run interactive test
run_interactive_test() {
    echo "Starting interactive Emacs test..."
    mkdir -p emacs.d

    print_warning "Emacs will open with your local ob-mermaid loaded"
    print_warning "Open test-example.org and test the code blocks with C-c C-c"

    emacs --init-directory=./emacs.d --load=./test-init.el test-example.org
}

# Run batch test
run_batch_test() {
    echo "Running batch test..."
    mkdir -p emacs.d

    # List of expected output files from test-example.org
    expected_files=(
        "test-sequence.png"
        "test-flowchart.png"
        "test-class.svg"
        "test-gantt.png"
        "test-git.png"
        "test-themed.png"
        "test-scaled.png"
        "test-output.pdf"
        "test-journey.png"
        "test-state.svg"
    )

    print_status "Processing all mermaid blocks in test-example.org..."

    emacs --batch --init-directory=./emacs.d --load=./test-init.el \
          --eval "(progn
                    (find-file \"test-example.org\")
                    (let ((block-count 0) (success-count 0))
                      (message \"[BATCH DEBUG] Starting search for mermaid blocks...\")
                      (goto-char (point-min))
                      (while (re-search-forward \"^[ \\\\t]*#\\\\+begin_src mermaid\\\\b\" nil t)
                        (setq block-count (1+ block-count))
                        (message \"[BATCH DEBUG] Found block %d at position %d\" block-count (point))
                        (let ((start-pos (match-beginning 0)))
                          (goto-char start-pos)
                          (condition-case err
                              (progn
                                (message \"[BATCH DEBUG] Executing block %d...\" block-count)
                                (org-babel-execute-src-block)
                                (setq success-count (1+ success-count))
                                (message \"[BATCH] Block %d executed successfully\" block-count))
                            (error
                              (message \"[BATCH] Block %d failed: %s\" block-count (error-message-string err))))
                          (goto-char (1+ start-pos))))
                      (message \"[BATCH] Processed %d blocks, %d successful\" block-count success-count)
                      (when (= block-count 0)
                        (message \"[BATCH DEBUG] No blocks found. Buffer contents:\")
                        (message \"%s\" (buffer-string))))
                    (save-buffer))" 2>&1

    # Check which files were created
    local created_count=0
    local total_count=${#expected_files[@]}

    echo "Checking generated files..."
    for file in "${expected_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "Created: $file ($(ls -lh "$file" | awk '{print $5}'))"
            created_count=$((created_count + 1))
        else
            print_warning "Missing: $file"
        fi
    done

    echo ""
    if [ $created_count -eq $total_count ]; then
        print_status "Batch test completed successfully - all $total_count files created"
        echo "Generated files:"
        ls -la test*.png test*.svg test*.pdf 2>/dev/null || true
        return 0
    else
        print_error "Batch test partially failed - $created_count/$total_count files created"
        return 1
    fi
}

# Validate ob-mermaid syntax
validate_syntax() {
    echo "Validating ob-mermaid.el syntax..."

    emacs --batch --eval "(progn
                            (add-to-list 'load-path default-directory)
                            (byte-compile-file \"ob-mermaid.el\"))" 2>&1

    if [ $? -eq 0 ]; then
        print_status "Syntax validation passed"
        rm -f ob-mermaid.elc  # Clean up compiled file
    else
        print_error "Syntax validation failed"
        return 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  check      - Check prerequisites only"
    echo "  clean      - Clean output files"
    echo "  syntax     - Validate syntax"
    echo "  batch      - Run batch test"
    echo "  interactive - Run interactive test (default)"
    echo "  all        - Run all tests"
    echo ""
}

# Main script logic
case "${1:-interactive}" in
    "check")
        check_prerequisites
        ;;
    "clean")
        clean_outputs
        ;;
    "syntax")
        check_prerequisites
        validate_syntax
        ;;
    "batch")
        check_prerequisites
        clean_outputs
        test_mermaid_cli
        validate_syntax
        run_batch_test
        ;;
    "interactive")
        check_prerequisites
        clean_outputs
        test_mermaid_cli
        validate_syntax
        run_interactive_test
        ;;
    "all")
        check_prerequisites
        clean_outputs
        test_mermaid_cli
        validate_syntax
        run_batch_test
        echo ""
        print_status "All tests completed! Starting interactive session..."
        run_interactive_test
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
