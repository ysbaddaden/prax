ensure_rack_app() {
  if [ ! -f "$1/config.ru" ]; then
    if [ ! -d "$1/public" ]; then
      echo "Error: this does not appear to be a rack app (config.ru is"
      echo "missing) and there isn't any public/ folder either."
      exit
    fi
  fi
}
