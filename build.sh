#!/bin/bash

path=$(cd "$(dirname "$0")"; pwd)
echo -e "\t${path}"

curl_git_url="https://github.com/curl/curl.git"
source_path="${path}/curl"
build_path="${path}/build"
target_path="${path}/target"

sdk_version=`xcrun --show-sdk-platform-version --sdk iphoneos`
xcode_path=`xcode-select -p`
clang_path="${xcode_path}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"


echo -e "chekcout git ..."
if [ ! -d "$source_path" ]; then
	git clone "$curl_git_url" "$source_path"  > /dev/null
fi
pushd "$source_path" > /dev/null
git checkout 
if [ ! -f "buildconf" ]; then
	echo -e "git clone ${curl_git_ur} fail.."
	exit 0
fi

if [ ! -f "configure" ]; then
	./buildconf
fi
popd > /dev/null



function build_libcurl() 
{
	arch=$1
	if [ $arch != "armv7" ] && [ $arch != "armv7s" ] && [ $arch != "arm64" ] && [ $arch != "x86_64" ]; then
		echo -e "unknow arch.."
		exit 0
	fi 
	platform="iPhoneOS"
	if [ $arch == "x86_64" ]; then
		platform="iPhoneSimulator"
	fi

	echo -e "build libcurl with ${arch}"
	pushd "${build_path}" > /dev/null
	mkdir -p "${target_path}/${arch}"
	export CFLAGS="-arch ${arch} -pipe -Os -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer/SDKs/${platform}.sdk -miphoneos-version-min=7.0"
	export LDFLAGS="-arch ${arch} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer/SDKs/${platform}.sdk"
	export CC="clang"
	export CXX="clang"
	$source_path/configure -prefix="${target_path}/${arch}" --host=${arch}-apple-darwin \
						--enable-static --disable-shared \
						--with-darwinssl \
						--enable-threaded-resolver \
						--disable-verbose \
						--enable-ipv6 \
						--disable-rtsp \
						--disable-imap \
						--disable-smb \
						--disable-telnet \
						--disable-pop3 \
						--disable-smtp \
						--disable-ldap \
						--disable-tftp \
						--disable-gopher \
						--disable-dict
	make 
	make install
	make distclean
	popd > /dev/null

}

mkdir -p "${build_path}"
mkdir -p "${target_path}"

build_libcurl armv7
build_libcurl arm64
build_libcurl x86_86

lipo -create "${target_path}/armv7/lib/libcurl.a" "${target_path}/arm64/lib/libcurl.a" "${target_path}/x86_64/lib/libcurl.a" "${path}/libcurl.a"

#arch_list=(armv7 armv7s arm64 i386 x86_64)
#for (( i=0; i<${#ARCHS[@]}; i++ )); do
#	build_libcurl ${ARCHS[$i]}
#done


#lipo -create ${CURRENTDIR}/wspx/Build/${SCHEME}-iphoneos/libWSPX.a ${CURRENTDIR}/wspx/Build/${SCHEME}-iphonesimulator/libWSPX.a -output ${CURRENTDIR}/wspx/Build/libWSPX_PUB.a
