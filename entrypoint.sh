#!/bin/bash
set -e

# ==============================================================================
# Apply Environment Variables to Custom PHP Configuration
# ==============================================================================
cat <<EOF > /usr/local/etc/php/conf.d/zz-custom-env.ini
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-512M}
post_max_size = ${PHP_POST_MAX_SIZE:-512M}
max_execution_time = ${PHP_MAX_EXECUTION_TIME:-300}
max_input_time = ${PHP_MAX_INPUT_TIME:-300}
max_input_vars = ${PHP_MAX_INPUT_VARS:-5000}
display_errors = ${PHP_DISPLAY_ERRORS:-Off}
display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS:-Off}
log_errors = ${PHP_LOG_ERRORS:-On}
date.timezone = ${TZ:-Asia/Tehran}
EOF

# ==============================================================================
# Start Background Services (PHP-FPM and Cron)
# ==============================================================================
php-fpm -D
crond -b -l 2

# ==============================================================================
# Dynamic Value Retrieval for Startup Banner
# ==============================================================================
PHP_VER=$(php -r "echo PHP_VERSION;")
APACHE_VER=$(httpd -v 2>&1 | head -n 1 | awk '{print $3}')
IONCUBE_LOADED=$(php -m | grep -i "ionCube Loader" > /dev/null && echo "Enabled" || echo "Disabled")
MEMORY_LIMIT=$(php -r "echo ini_get('memory_limit');")
MAX_EXEC_TIME=$(php -r "echo ini_get('max_execution_time');")
UPLOAD_MAX=$(php -r "echo ini_get('upload_max_filesize');")
POST_MAX=$(php -r "echo ini_get('post_max_size');")
OPCACHE_STATUS=$(php -r "echo ini_get('opcache.enable') ? 'Enabled' : 'Disabled';")

CRON_FILES=$(find /etc/cron.d -type f ! -name ".*" 2>/dev/null | wc -l)
if [ "$CRON_FILES" -gt 0 ]; then
    CRON_STATUS="Enabled (${CRON_FILES} job file(s) found in /etc/cron.d)"
else
    CRON_STATUS="Enabled (No custom job files in /etc/cron.d)"
fi

# ==============================================================================
# Print Full Startup Banner
# ==============================================================================
echo "=========================================================================="
echo "               PersianNIT PHP + Apache Alpine Container                   "
echo "=========================================================================="
echo " Web Server & Engine Environment:"
echo "   - Web Server           : ${APACHE_VER}"
echo "   - PHP Version          : ${PHP_VER}"
echo "   - PHP Mode             : FastCGI (PHP-FPM)"
echo "   - ionCube Loader       : ${IONCUBE_LOADED}"
echo "   - Memory Limit         : ${MEMORY_LIMIT}"
echo "   - Max Execution Time   : ${MAX_EXEC_TIME}s"
echo "   - Upload Max Filesize  : ${UPLOAD_MAX}"
echo "   - Post Max Size        : ${POST_MAX}"
echo "   - OPcache Status       : ${OPCACHE_STATUS}"
echo "   - Timezone             : ${TZ:-Asia/Tehran}"
echo "--------------------------------------------------------------------------"
echo " Container Services & Automation:"
echo "   - Cron Service (dcron) : ${CRON_STATUS}"
echo "   - Auto Unzip           : ${AUTO_UNZIP:-false} ${AUTO_UNZIP_FILE:+(File: $AUTO_UNZIP_FILE)}"
echo "   - Auto Chown           : ${AUTO_CHOWN:-false}"
echo "   - Auto Fix Permissions : ${AUTO_FIX_PERMISSIONS:-false}"
echo "   - Writable Directories : ${WRITABLE_DIRS:-None}"
echo "=========================================================================="
echo ""

# ==============================================================================
# Writable Directories Setup
# ==============================================================================
if [ -n "$WRITABLE_DIRS" ]; then
    for dir in $WRITABLE_DIRS; do
        TARGET_DIR="/var/www/html/$dir"
        if [ ! -d "$TARGET_DIR" ]; then
            echo "--> Creating missing writable directory: $TARGET_DIR"
            mkdir -p "$TARGET_DIR"
        fi
        if [ "$AUTO_FIX_PERMISSIONS" = "true" ]; then
            chmod -R 775 "$TARGET_DIR"
        fi
    done
fi

# ==============================================================================
# Auto Ownership Fix
# ==============================================================================
if [ "$AUTO_CHOWN" = "true" ]; then
    echo "--> Setting ownership to www-data:www-data on /var/www/html..."
    chown -R www-data:www-data /var/www/html
fi

# ==============================================================================
# Auto Unzip Logic
# ==============================================================================
if [ "$AUTO_UNZIP" = "true" ] && [ -n "$AUTO_UNZIP_FILE" ]; then
    ZIP_PATH="/var/www/html/$AUTO_UNZIP_FILE"
    if [ -f "$ZIP_PATH" ]; then
        echo "--> Auto-unzipping $ZIP_PATH to /var/www/html..."
        unzip -o "$ZIP_PATH" -d /var/www/html/
        rm -f "$ZIP_PATH"
        echo "--> Extraction complete and source archive removed."
    fi
fi

# Launch Apache in Foreground
exec httpd -D FOREGROUND