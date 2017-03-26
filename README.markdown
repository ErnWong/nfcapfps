# nfcapfps

[![Build Status](https://travis-ci.org/ErnWong/nfcapfps.svg?branch=master)](https://travis-ci.org/ErnWong/nfcapfps)

```sh
nfcapfps <fps>
```

Pipes stdin to stdout, but makes sure there has elapsed at least `1 / fps` seconds since the previous write before writing again.
