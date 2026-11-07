#!/usr/bin/env python3
"""Upload the validated release ZIP to the Factorio Mod Portal; safe to retry with the same bytes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

import validate_package

PORTAL = 'https://mods.factorio.com'


def request_json(url, fields=None, archive=None, token=None):
    """GET, or POST multipart fields and an optional ZIP sent as `file`; returns the JSON reply."""
    headers, body = {}, None
    if fields is not None:
        boundary = uuid.uuid4().hex
        sections = [f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode()
                    for key, value in fields.items()]
        if archive is not None:
            sections.append((f'--{boundary}\r\nContent-Disposition: form-data; name="file"; '
                             f'filename="{archive.name}"\r\nContent-Type: application/zip\r\n\r\n').encode())
            sections.extend([archive.read_bytes(), b'\r\n'])
        sections.append(f'--{boundary}--\r\n'.encode())
        body = b''.join(sections)
        headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary
    if token is not None:
        headers['Authorization'] = 'Bearer ' + token
    request = urllib.request.Request(url, data=body, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def listing(name):
    # The portal's CDN caches this reply for 15 minutes, which would hide a new upload from verification.
    # A query string the cache has never seen always reaches the portal.
    try:
        return request_json(f'{PORTAL}/api/mods/{urllib.parse.quote(name, safe="")}?fresh={uuid.uuid4().hex}')
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        raise


def version_parts(version):
    return tuple(int(part) for part in version.split('.'))


def published(mod, version, archive):
    for release in (mod or {}).get('releases', []):
        if release['version'] == version:
            if release['file_name'] != archive.name or release['sha1'] != hashlib.sha1(archive.read_bytes()).hexdigest():
                raise ValueError('This portal version already has different package bytes')
            return True
    return False


def publish(output, tag, token):
    validate_package.validate(output)
    info = json.loads(validate_package.release_source('info.json').read_text())
    if tag != 'v' + info['version']:
        raise ValueError('Release tag must match info.json')
    archive = output / f'{info["name"]}_{info["version"]}.zip'
    if not token:
        raise ValueError('Connect FACTORIO_API_KEY before publishing to the portal')
    mod = listing(info['name'])
    if mod is None:
        raise ValueError('The portal listing does not exist; publish the first release manually')
    if published(mod, info['version'], archive):
        print('The portal already has this exact package')
        return
    if any(version_parts(item['version']) > version_parts(info['version']) for item in mod.get('releases', [])):
        raise ValueError('A newer version is already published on the portal')
    initialized = request_json(PORTAL + '/api/v2/mods/releases/init_upload', {'mod': info['name']}, token=token)
    url = initialized.get('upload_url', '')
    parsed = urllib.parse.urlparse(url)
    if initialized.get('error') or parsed.scheme != 'https' or not parsed.netloc or parsed.username or parsed.password:
        raise ValueError('The portal did not provide a valid HTTPS upload destination')
    # The upload URL carries its own authorization. Never forward the API key or log the URL.
    result = request_json(url, {}, archive=archive)
    if result.get('success') is not True:
        raise ValueError('The portal rejected the package; retry the same tag after checking its state')
    deadline = time.monotonic() + 60
    while True:
        if published(listing(info['name']), info['version'], archive):
            print('Verified portal publication of ' + archive.name)
            return
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise ValueError('Portal verification is pending; retry the same tag without changing its bytes')
        time.sleep(min(5, remaining))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--output', type=Path, default=validate_package.ROOT / 'build/dist')
    args = parser.parse_args()
    try:
        publish(args.output, args.tag, os.environ.get('FACTORIO_API_KEY'))
    except urllib.error.HTTPError as error:
        raise SystemExit(f'Factorio HTTP {error.code}; verify credentials and retry the same tag') from None
    except (urllib.error.URLError, TimeoutError):
        raise SystemExit('Factorio connection failed; check the portal before retrying the same tag') from None
