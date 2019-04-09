# WireGuard builds for CoreOS
Automatically built WireGuard [torcx](https://github.com/coreos/torcx) packages for CoreOS releases `>2020.0.0`

Built by [Travis CI](https://travis-ci.org/miguelangel-nubla/WireGuard-CoreOS/) to the [releases page](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases) of this GitHub repository.

## Getting Started
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
At the time of writing, building the latest WireGuard sources result in a Segmentation fault on the CoreOS developer container.\
The [Travis CI job](https://travis-ci.org/miguelangel-nubla/WireGuard-CoreOS/) will keep trying daily until the upstream code is fixed. Therefore the [releases page](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases) will always have the latest release compatible with CoreOS.

## Based on
* https://github.com/coreos/bugs/issues/2225#issuecomment-351578984
* https://github.com/nopdotcom/coreos-build-wireguard