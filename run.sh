#!/bin/bash
set -e -v -x


sudo rm -Rf .tmp
mkdir -p .tmp
cp build-torcx-wireguard.sh .tmp/
cd .tmp

PKG=WireGuard
PKG_REPO="https://github.com/WireGuard/WireGuard"
echo "Downloading WireGuard sources from ${PKG_REPO}"
git clone -q "${PKG_REPO}" "${PKG}-source"


#gpg2 --keyserver pool.sks-keyservers.net --recv-keys 04127D0BFABEC8871FFB2CCE50E0885593D2DCB4
curl -s -O https://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.asc
gpg2 -q --import --keyid-format LONG CoreOS_Image_Signing_Key.asc

for GROUP in stable beta alpha
do
	# only build for version > 2020
	for VERSION in $(curl -s https://coreos.com/releases/releases-$GROUP.json | jq -r 'keys | map(split(".")) | map(select(.[0] | tonumber > 2020)) | map(join(".")) | sort | reverse | .[0:3] | .[]')
	do
		url="https://$GROUP.release.core-os.net/amd64-usr/${VERSION}/coreos_developer_container.bin.bz2"
		localimage="coreos_developer_container-${GROUP}_${VERSION}.bin"
		logfile="$PWD/${PKG}.log"

		echo "Downloading $url"
		curl -Ls "$url" -o "$localimage.bz2"
		gpg2 -q --verify <(curl -Ls "$url.sig") "$localimage.bz2" 2>/dev/null
		bzip2 -df "$localimage.bz2"

		# fallback to previous versions until one is built without errors
		for BUILD_TAG in $(git -C WireGuard-source tag --sort=-refname | head -15)
		do
			git -C WireGuard-source checkout -q "${BUILD_TAG}"

			REFERENCE="CoreOS_${VERSION}"
			#check if WireGuard release for this CoreOS version is already built and published in the GitHub repository
			url="https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases/download/${BUILD_TAG}/${PKG}.${REFERENCE}.torcx.tgz"
			if [ $TRAVIS ] && [ $(curl -L --write-out %{http_code} --silent --output /dev/null "$url") -eq 200 ] ;
			then
				echo "Release ${BUILD_TAG} for ${REFERENCE} found in $url, skipping"
			    break
			fi

			ITEM="WireGuard release ${BUILD_TAG} for CoreOS ${GROUP} ${VERSION}"
			echo "Trying to build $ITEM"
			if sudo systemd-nspawn -q --bind="$PWD:/host" --image="$localimage" /bin/bash /host/build-torcx-wireguard.sh "${PKG}" "${BUILD_TAG}"
			then
				sudo mv -f "${PKG}:${BUILD_TAG}.torcx.tgz" "${PKG}.${REFERENCE}.torcx.tgz"
				echo "Success building $ITEM"

				if [ $TRAVIS ]
				then
					echo "Uploading to GitHub releases..."
					ghr -b "Automatic [Travis CI](https://travis-ci.org/miguelangel-nubla/WireGuard-CoreOS/) build. If the package for your CoreOS release is not in this tag then it is not compatible. Look for a previous WireGuard release or take a look at [latest-all](https://github.com/miguelangel-nubla/WireGuard-CoreOS/releases/tag/latest-all)" -replace "${BUILD_TAG}" "${PKG}.${REFERENCE}.torcx.tgz"
					ghr -b "This is a helper release tag with the latest WireGuard binaries for each CoreOS release. Note that WireGuard versions differ between packages." -replace "latest-all" "${PKG}.${REFERENCE}.torcx.tgz"
					echo "Done."
				fi

				sudo rm -f "${PKG}:${REFERENCE}.torcx.tgz"
				break
			else
				echo "Error building $ITEM"
			fi
		done

		rm "$localimage"
	done
done

rm -Rf .tmp

echo "Success!"