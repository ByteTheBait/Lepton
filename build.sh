#!/bin/sh
# Build the lepton demo. Needs an Ionic compiler with the term_* runtime
# builtins. Defaults to the sibling ../ionic/ionic_new; override with IONIC=...
set -e
IONIC="${IONIC:-}"
if [ -z "$IONIC" ]; then
    if [ -x ../ionic/ionic_new ]; then IONIC=../ionic/ionic_new
    elif [ -x ../ionic/ionic ]; then IONIC=../ionic/ionic
    elif command -v ionic >/dev/null 2>&1; then IONIC=ionic
    else echo "lepton: cannot find an Ionic compiler; set IONIC=/path/to/ionic" >&2; exit 1; fi
fi
echo "==> compiling lepton demo with $IONIC"
"$IONIC" examples/demo.ionic -o demo
echo "==> built ./demo"
