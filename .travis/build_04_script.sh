#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

TRAVIS_COMMIT_LOG=$(git log --format=fuller -1)
export TRAVIS_COMMIT_LOG

echo "list all users on docker?"
DOCKER_EXEC cut -d: -f1 /etc/passwd

echo "DOCKER_EXEC pwd"
DOCKER_EXEC pwd
ls -la

OUTDIR=$BASE_OUTDIR/$TRAVIS_PULL_REQUEST/$TRAVIS_JOB_NUMBER-$HOST
BITCOIN_CONFIG_ALL="--disable-dependency-tracking --prefix=$TRAVIS_BUILD_DIR/depends/$HOST --bindir=$OUTDIR/bin --libdir=$OUTDIR/lib"
if [ -z "$NO_DEPENDS" ]; then
  DOCKER_EXEC su -c travis -s ccache --max-size=$CCACHE_SIZE
fi

BEGIN_FOLD autogen
if [ -n "$CONFIG_SHELL" ]; then
  DOCKER_EXEC "$CONFIG_SHELL" -c "./autogen.sh"
else
  DOCKER_EXEC su -c travis -s ./autogen.sh
fi
END_FOLD

mkdir build
cd build || (echo "could not enter build directory"; exit 1)

pwd
echo "ls -la"
ls -la
echo "ls -la ../"
ls -la ../
echo "ls -la ../../ end listing"
ls -la ../../

#sudo chattr -i /home/travis/build/project-liberty/wallet/Makefile.in
#sudo chattr -i /home/travis/build/project-liberty/wallet/configure
#sudo chattr -i /home/travis/build/project-liberty/wallet/allocal.m4
#sudo chattr -i /home/travis/build/project-liberty/wallet/build

#chown travis:travis /home/travis/build/project-liberty/wallet/Makefile.in
#chown travis:travis /home/travis/build/project-liberty/wallet/configure
#chown travis:travis /home/travis/build/project-liberty/wallet/allocal.m4
#chown travis:travis /home/travis/build/project-liberty/wallet/autom4te.cache
#chown travis:travis /home/travis/build/project-liberty/wallet/build

BEGIN_FOLD configure
   # DOCKER_EXEC ../configure --cache-file=config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false) && make VERSION=$HOST
  DOCKER_EXEC su -c travis -s ../configure --cache-file=config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false)
END_FOLD

echo "next is make VERSION=$HOST" 

pwd
ls -la
ls -la ../
ls -la ../../

BEGIN_FOLD distdir
#DOCKER_EXEC make VERSION=$HOST
   DOCKER_EXEC make VERSION=$HOST
END_FOLD

DOCKER_EXEC cd "liberty-$HOST" || (echo "could not enter distdir liberty-$HOST"; exit 1)

pwd
ls -la
ls -la ../
ls -la ../../

BEGIN_FOLD configure
   # DOCKER_EXEC CONFIG_SHELL= ./configure --cache-file=../config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false) 
   DOCKER_EXEC su -c travis -s ./configure --cache-file=../config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG || ( cat config.log && false) 
END_FOLD

pwd
ls -la
ls -la ../
ls -la ../../

BEGIN_FOLD build
   DOCKER_EXEC su -c travis -s make $MAKEJOBS $GOAL || ( echo "Build failure. Verbose build follows." && DOCKER_EXEC su -c travis -s make $GOAL V=1 ; false )
END_FOLD

if [ "$RUN_UNIT_TESTS" = "true" ]; then
  BEGIN_FOLD unit-tests
  #DOCKER_EXEC LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib make $MAKEJOBS check VERBOSE=1
  END_FOLD
fi

if [ "$RUN_BENCH" = "true" ]; then
  BEGIN_FOLD bench
  #DOCKER_EXEC LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib $OUTDIR/bin/bench_liberty -scaling=0.001
  END_FOLD
fi

if [ "$TRAVIS_EVENT_TYPE" = "cron" ]; then
  extended="--extended --exclude feature_pruning,feature_dbcrash"
fi

if [ "$RUN_FUNCTIONAL_TESTS" = "true" ]; then
  BEGIN_FOLD functional-tests
  #DOCKER_EXEC test/functional/test_runner.py --combinedlogslen=4000 --coverage --quiet --failfast ${extended}
  END_FOLD
fi