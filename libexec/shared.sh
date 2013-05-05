ensure_rack_app() {
    if [ ! -f "$1/config.ru" ]; then
        echo "Error: this does not appear to be a rack app (config.ru is missing)"
        exit
    fi
}
