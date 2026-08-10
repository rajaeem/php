<h1>Docker Image: <code>own3r1138/php</code></h1>

<p>Production-ready <b>Apache + PHP-FPM (Alpine)</b> Docker image built with local <b>ionCube Loader</b>, <b>Cron Daemon support (dcron)</b>, <b>Zend Opcache</b>, <b>Reverse Proxy / SSL Forwarding Fixes</b>, <b>Auto-Permission fixing</b>, and <b>Zip Extraction</b>. Ideal for running web applications like WHMCS, WordPress, Laravel, Altum-based scripts, or custom PHP solutions requiring standard <code>.htaccess</code> support.</p>

<hr>

## Key Features

<ul>
  <li><b>Multi-PHP Version Support:</b> Flexibly build from <b>PHP 7.4</b> up to <b>PHP 8.5</b> via build arguments (<code>ARG PHP_VERSION</code>).</li>
  <li><b>Local ionCube Loader:</b> Installs directly from the local archive without external network download dependencies during build.</li>
  <li><b>Apache + PHP-FPM Integration:</b> Native Alpine Apache with <code>mod_proxy_fcgi</code>, enabling full <code>.htaccess</code> rewrite support and low memory overhead without requiring Supervisord.</li>
  <li><b>Reverse Proxy &amp; HTTPS Ready:</b> Pre-configured with <code>mod_remoteip</code> and <code>X-Forwarded-Proto</code> handling to eliminate <code>302 ERR_TOO_MANY_REDIRECTS</code> loops behind Cloudflare, Traefik, or Nginx.</li>
  <li><b>Built-in Cron Daemon:</b> Runs background <code>dcron</code> automatically with task execution monitored directly from <code>/etc/cron.d</code>.</li>
  <li><b>Smart Permission &amp; Ownership Management:</b> Auto-configures directory structures, directory permissions (<code>775</code>), and file permissions assigned to <code>www-data:www-data</code>.</li>
  <li><b>Auto ZIP Extraction:</b> Automatically unpacks designated web application ZIP files (<code>app.zip</code> or custom target) upon container startup.</li>
  <li><b>Includes Essential Modules:</b> Pre-packaged with <code>mysqli</code>, <code>pdo_mysql</code>, <code>gd</code>, <code>zip</code>, <code>intl</code>, <code>mbstring</code>, <code>redis</code>, <code>imagick</code>, <code>bcmath</code>, <code>soap</code>, <code>xsl</code>, <code>opcache</code>, <code>xmlrpc</code>, and <code>curl</code>.</li>
  <li><b>Integrated Healthcheck:</b> Dedicated script monitoring both <b>Apache / HTTP Status (200–399)</b> and <b>Cron Daemon</b> execution.</li>
</ul>

<hr>

## Quick Start (Docker Compose)

<p>Add the following to your <code>docker-compose.yml</code>:</p>

<pre><code>version: '3.8'

services:
  web:
    image: own3r1138/php:7.4-ioncube
    container_name: my_php_app
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      TZ: "Asia/Tehran"
      PHP_MEMORY_LIMIT: "512M"
      PHP_MAX_EXECUTION_TIME: "300"
      PHP_UPLOAD_MAX_FILESIZE: "512M"
      PHP_POST_MAX_SIZE: "512M"
      AUTO_UNZIP: "true"
      AUTO_UNZIP_FILE: "app.zip"
      AUTO_CHOWN: "true"
      AUTO_FIX_PERMISSIONS: "true"
      WRITABLE_DIRS: "uploads cache storage logs tmp sessions"
    volumes:
      - ./data:/var/www/html
      # (Optional) Mount custom cron task
      # - ./cron/my-cron:/etc/cron.d/my-cron
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
</code></pre>

<hr>

## Environment Variables Configuration

<table>
  <thead>
    <tr>
      <th>Variable</th>
      <th>Default</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>TZ</code></td>
      <td><code>Asia/Tehran</code></td>
      <td>Sets container OS and PHP system time zone</td>
    </tr>
    <tr>
      <td><code>PHP_MEMORY_LIMIT</code></td>
      <td><code>512M</code></td>
      <td>Sets <code>memory_limit</code> in custom PHP config</td>
    </tr>
    <tr>
      <td><code>PHP_UPLOAD_MAX_FILESIZE</code></td>
      <td><code>512M</code></td>
      <td>Maximum allowed file upload size</td>
    </tr>
    <tr>
      <td><code>PHP_POST_MAX_SIZE</code></td>
      <td><code>512M</code></td>
      <td>Maximum allowed POST request payload size</td>
    </tr>
    <tr>
      <td><code>PHP_MAX_EXECUTION_TIME</code></td>
      <td><code>300</code></td>
      <td>Max script execution timeout in seconds</td>
    </tr>
    <tr>
      <td><code>PHP_MAX_INPUT_TIME</code></td>
      <td><code>300</code></td>
      <td>Max input parsing time in seconds</td>
    </tr>
    <tr>
      <td><code>PHP_MAX_INPUT_VARS</code></td>
      <td><code>5000</code></td>
      <td>Maximum allowed GET/POST input variables</td>
    </tr>
    <tr>
      <td><code>PHP_DISPLAY_ERRORS</code></td>
      <td><code>Off</code></td>
      <td>Displays or hides PHP runtime errors</td>
    </tr>
    <tr>
      <td><code>PHP_LOG_ERRORS</code></td>
      <td><code>On</code></td>
      <td>Enables error logging to container log stream</td>
    </tr>
    <tr>
      <td><code>AUTO_UNZIP</code></td>
      <td><code>false</code></td>
      <td>Extract target archive into <code>/var/www/html</code> on boot</td>
    </tr>
    <tr>
      <td><code>AUTO_UNZIP_FILE</code></td>
      <td><code>""</code></td>
      <td>Name of the ZIP archive stored inside <code>/var/www/html</code></td>
    </tr>
    <tr>
      <td><code>AUTO_CHOWN</code></td>
      <td><code>false</code></td>
      <td>Chown web root files to <code>www-data:www-data</code></td>
    </tr>
    <tr>
      <td><code>AUTO_FIX_PERMISSIONS</code></td>
      <td><code>false</code></td>
      <td>Sets standard <code>775</code> permissions on target writable directories</td>
    </tr>
    <tr>
      <td><code>WRITABLE_DIRS</code></td>
      <td><code>None</code></td>
      <td>Target directories inside <code>/var/www/html</code> to apply write permissions</td>
    </tr>
  </tbody>
</table>

<hr>

## How to Enable Cron Tasks

<p>Cron is managed natively via <code>dcron</code>. To run cron jobs inside the container:</p>

<ol>
  <li>
    Create a crontab file locally (e.g., <code>app-cron</code>):
    <pre><code>*/5 * * * * www-data php -q /var/www/html/cron.php > /dev/null 2>&1
</code></pre>
  </li>
  <li>
    Mount it inside the <code>/etc/cron.d/</code> directory in your Compose setup:
    <pre><code>volumes:
  - ./app-cron:/etc/cron.d/app-cron
</code></pre>
  </li>
</ol>

<p><i>(Note: Always ensure your cron files end with a blank trailing newline).</i></p>

<hr>

## Building from Source

<p>To build a specific PHP version locally using your target image tags:</p>

<pre><code># PHP 7.4 with ionCube
docker build --no-cache --pull --build-arg PHP_VERSION=7.4 --build-arg WITH_IONCUBE=true -t own3r1138/php:7.4-ioncube .

# PHP 7.4 without ionCube
docker build --no-cache --pull --build-arg PHP_VERSION=7.4 --build-arg WITH_IONCUBE=false -t own3r1138/php:7.4 .

# PHP 8.5 with ionCube
docker build --no-cache --pull --build-arg PHP_VERSION=8.5 --build-arg WITH_IONCUBE=true -t own3r1138/php:8.5-ioncube .

# PHP 8.5 without ionCube
docker build --no-cache --pull --build-arg PHP_VERSION=8.5 --build-arg WITH_IONCUBE=false -t own3r1138/php:8.5 .
</code></pre>
