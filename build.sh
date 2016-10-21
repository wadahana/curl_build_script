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
git reset --hard HEAD
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
	host="arm-apple-darwin"
	if [ $arch == "x86_64" ]; then
		platform="iPhoneSimulator"
		host="x86_64-apple-darwin"
	fi
	
	if [ -f "${build_path}/Makefile" ]; then
	    pushd "${build_path}" > /dev/null
        make distclean
        popd
	fi

	echo -e "build libcurl with ${arch}"
	pushd "${build_path}" > /dev/null
	mkdir -p "${target_path}/${arch}"
	export CFLAGS="-arch ${arch} -pipe -Os -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer/SDKs/${platform}.sdk -miphoneos-version-min=7.0"
	export LDFLAGS="-arch ${arch} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer/SDKs/${platform}.sdk"
	export CC="clang"
	export CXX="clang"
	$source_path/configure -prefix="${target_path}/${arch}" --host=${host} \
						--enable-static --disable-shared \
						--disable-debug \
						--disable-curldebug \
						--with-darwinssl \
						--enable-threaded-resolver \
						--enable-verbose \
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


	sed -i .config.bak 's/^#define HAVE_CLOCK_GETTIME_MONOTONIC 1/\/* #undef HAVE_CLOCK_GETTIME_MONOTONIC *\//g' ${build_path}/lib/curl_config.h

	make -j 2
	make install
	popd > /dev/null

}

mkdir -p "${build_path}"
mkdir -p "${target_path}"

build_libcurl armv7
build_libcurl arm64
build_libcurl x86_64

lipo -create "${target_path}/armv7/lib/libcurl.a" "${target_path}/arm64/lib/libcurl.a" "${target_path}/x86_64/lib/libcurl.a" -o "${path}/libcurl.a"
rm -r "${path}/include"
cp -r "${target_path}/arm64/include/curl" "${path}/include"
pushd "${path}/include" > /dev/null
patch -p1 <../headers.patch 
popd
