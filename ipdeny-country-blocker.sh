#!/bin/bash

IPDENY="http://www.ipdeny.com/ipblocks/data/countries"
IPDENY_CHAIN="ipdeny"
IPTABLES="iptables -v -w"

TMPDIR=$(mktemp -d)

if ${IPTABLES} -C INPUT -j ${IPDENY_CHAIN}; then
  echo "Target chain ${IPDENY_CHAIN} exists, flushing it."
  ${IPTABLES} -F ${IPDENY_CHAIN}
  sleep 2
else
  echo "Creating chain ${IPDENY_CHAIN}"
  ${IPTABLES} -N ${IPDENY_CHAIN}
  ${IPTABLES} -I INPUT -j ${IPDENY_CHAIN}
  sleep 2
fi

(
  cd ${TMPDIR}
  wget -O ${TMPDIR}/MD5SUM ${IPDENY}/MD5SUM
  for i in $@; do
    wget -O ${TMPDIR}/${i}.zone ${IPDENY}/${i}.zone
    if grep -q $(md5sum ${i}.zone) ${TMPDIR}/MD5SUM; then
      while read cidr; do
        comment="${i} $(date)"
        ${IPTABLES} -A ${IPDENY_CHAIN} -s ${cidr} -j DROP -m comment --comment "${comment}"
        if [[ $? -ne 0 ]]; then
          echo "Failed to add ${cidr}"
        fi
      done < ${TMPDIR}/${i}.zone
    else
      echo "MD5 hash does not match for ${i}.zone"
    fi
  done
  rm -rf ${TMPDIR}
)
