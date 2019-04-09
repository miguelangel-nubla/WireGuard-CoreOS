
# WireGuard builds for CoreOS
Automatically built WireGuard [torcx](https://github.com/coreos/torcx) packages for latest CoreOS releases.

Built by [Travis CI](https://travis-ci.org/miguelangel-nubla/WireGuard-CoreOS/) to the [releases page](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases) of this GitHub repository.

## Getting Started

### Via Container Linux Config and Ignition (preferred)
You can use [the example Container Linux Config](container_linux_config.yml), then [convert it]([https://github.com/coreos/container-linux-config-transpiler](https://github.com/coreos/container-linux-config-transpiler)) onto a ignition.json file and provide it to your CoreOS instances.

### Manually
* Download the torcx package for your CoreOS release from the [releases page](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases) to your torcx folder.
```
source /etc/os-release
wget https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases/download/latest-all/WireGuard.CoreOS_${VERSION_ID}.torcx.tgz \
-O /var/lib/torcx/store/${VERSION_ID}/WireGuard:CoreOS_${VERSION_ID}.torcx.tgz
```
* Add a new torcx profile.
```
jq '.value.images += [{ "name": "WireGuard", "reference": "'CoreOS_${VERSION_ID}'" }]' /usr/share/torcx/profiles/vendor.json > /etc/torcx/profiles/wg.json
```
* `echo wg > /etc/torcx/next-profile`
* Reboot. WireGuard should be available in `/run/torcx/bin/wg`

## Build yourself
For Ubuntu, git clone this repo, then
```
cd WireGuard-CoreOS
sudo apt-get update
sudo apt-get install -y curl gpg2 bzip2 systemd-container dirmngr
bash run.sh
```
Packages will be at `output/`

## Notes
At the time of writing, building the latest WireGuard sources result in a Segmentation fault on most of the CoreOS developer container releases.\
The [Travis CI job](https://travis-ci.org/miguelangel-nubla/WireGuard-CoreOS/) will keep trying daily until the upstream code is fixed.

#### The tag `latest-all` on the [releases page](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases/tag/latest-all) will always have the latest WireGuard release compatible with each respective CoreOS release.

## Based on
* https://github.com/coreos/bugs/issues/2225#issuecomment-351578984
* https://github.com/nopdotcom/coreos-build-wireguard