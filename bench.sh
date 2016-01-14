set -e

# Clean up previous test
rm log.log || true
rm -rf .git .hg .bup

# Specify how our file is going to be constructed
NUMS="00 01 02 03 04 05 06 07 08 09"
F1="00                           "
F2="00 01 02                     "
F3="00 01 02       05 06    08   "
F4="00 01 02       05 06 07 08   "
F5="00 01 02       05 06 07 08 09"
F6="00 01 02 03 04 05 06 07 08 09"

echo "Getting random files"
for i in $NUMS; do
    # Tweak 'count' and remove all the random files in the current dir
    # to modify the number of MB per chunk
    [ -f "$i.rnd" ] || dd if=/dev/urandom of=./$i.rnd bs=1M count=75 1>/dev/null 2>&1
done

FMTSTR="Total: %e    User: %U    System: %S"

GITCOMMIT="git add file && git commit -m commit"
HGCOMMIT="hg commit -m commit -u test file"
BUPCOMMIT="bup split -n test file"

BENCHCOMMIT="
/usr/bin/time --format='git: $FMTSTR' --output=log.log --append bash -l <(echo '$GITCOMMIT') &&
/usr/bin/time --format='hg:  $FMTSTR' --output=log.log --append bash -l <(echo '$HGCOMMIT') &&
/usr/bin/time --format='bup: $FMTSTR' --output=log.log --append bash -l <(echo '$BUPCOMMIT')
"

echo $BENCHCOMMIT

rm -f file && touch file
# Setup git and tune to be more like mercurial
git init
git config --local core.bigFileThreshold 4G
git config --local core.compression 0
git config --local core.loosecompression 0
git config --local pack.compression 0
git config --local pack.window 1
git config --local pack.depth 1
git config --local pack.deltaCacheSize 1G
# Setup mercurial
hg init
hg add file
# Setup bup
BUP_DIR=./.bup
export BUP_DIR
bup init

# Perform the benchmark
rm -f file && for i in $F1; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")
rm -f file && for i in $F2; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")
rm -f file && for i in $F3; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")
rm -f file && for i in $F4; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")
rm -f file && for i in $F5; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")
rm -f file && for i in $F6; do cat $i.rnd >> file; done && bash -l <(echo "$BENCHCOMMIT")

# Print out some some interesting things at the end
cat log.log | grep git && cat log.log | grep hg && cat log.log | grep bup
du -sh .bup .git .hg








