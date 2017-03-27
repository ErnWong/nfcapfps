#!/bin/sh

test_description='Test basic functionality'

. ./sharness.sh

sequence()
(
  first=$1 incr=$2 last=$3
  echo "for (i = $first; i <= $last; i+=$incr) i" | bc -l
)

test_expect_success 'missing argument should exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps
"

test_expect_success 'too many arguments should exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps 24 64
"

test_expect_success 'reject fps of 0 - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps 0
"

test_expect_success 'reject fps of nan - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps nan
"

test_expect_success 'reject fps of -ve - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps -35
"

test_expect_success 'reject non number fps - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps wat
"

test_expect_success 'writes correct output' "
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >expected &&
  while read line; do echo \$line; done <expected | nfcapfps 24 >actual &&
  test_cmp actual expected
"

test_expect_success 'allows fps=inf' "
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >expected &&
  while read line; do echo \$line; done <expected | nfcapfps 24 >actual &&
  test_cmp actual expected
"

test_expect_success 'does not send too early (fps=20)' "
  printf '%1000s' | sed 's/ /0\\n/g' >expected &&
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >theinput &&
  while read line; do echo \$line; done <theinput |
  nfcapfps 20 |
  (
    NANO_PREV=0
    while read line; do
      NANO_CURR=\$(date +%s%N)
      DELTA=\`NANOCURR - NANO_PREV\`
      if [ \"\$DELTA\" -gt \"50000000\" ]; then
        echo 1
      else
        echo 0
      fi
      NANO_PREV=\$NANO_CURR
    done
  ) >actual &&
  test_cmp actual expected
"

test_expect_success 'does not send too early (fps=4)' "
  printf '%1000s' | sed 's/ /0\\n/g' >expected &&
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >theinput &&
  while read line; do echo \$line; done <theinput |
  nfcapfps 20 |
  (
    NANO_PREV=0
    while read line; do
      NANO_CURR=\$(date +%s%N)
      DELTA=\`NANOCURR - NANO_PREV\`
      if [ \"\$DELTA\" -gt \"250000000\" ]; then
        echo 1
      else
        echo 0
      fi
      NANO_PREV=\$NANO_CURR
    done
  ) >actual &&
  test_cmp actual expected
"

test_expect_success 'supports float as fps arg (fps=0.25)' "
  printf '%1000s' | sed 's/ /0\\n/g' >expected &&
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >theinput &&
  while read line; do echo \$line; done <theinput |
  nfcapfps 0.25 |
  (
    NANO_PREV=0
    while read line; do
      NANO_CURR=\$(date +%s%N)
      DELTA=\`NANOCURR - NANO_PREV\`
      if [ \"\$DELTA\" -gt \"4000000000\" ]; then
        echo 1
      else
        echo 0
      fi
      NANO_PREV=\$NANO_CURR
    done
  ) >actual &&
  test_cmp actual expected
"

test_expect_success '--count prints to fd 3 with correct integer sequence' "
  sequence 1 1000 1 >expected &&
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >theinput &&
  nfcycler --count 24 3>actual &&
  test_cmp actual expected
"

test_expect_success '--bufsize allows exact amount of large payloads be emitted'"
  echo 10 >expected &&
  printf '%10000s' | sed 's/ /\0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >theinput &&
  nfcycler 24 --count --bufsize 20000 <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--group complains about missing arg' "
  test_must_fail nfcapfps 24 --group
"

test_expect_success '--group json emits exact amount of complete json payloads' "
  echo 7 >expected &&
  printf '{}
  { \"a\": 2,
    \"012caa\": [1, 2, 3] } { \"a\":
    \"a{{\",
    \"b\": { \"c\": [0] }
  }
  [
    \"a\": \"]b\"
  ]
  { \"d\": 0 }%10000s
  {
    %10000s
    \"a\": 0
    %10000s
    ,
    \"b\": 1
  }
  []' >theinput &&
  nfcycler 24 --group json --count <theinput | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--group csv emits exact amount of newline entries' "
  printf '%10000s' | sed 's/ /\0/g'
  printf '%10s' | sed 's/ /\$RANDOM\\n/g' >theinput &&
"

test_expect_success '--delimiter "\n" emits exact amount of newline entries' "
  echo 10 >expected &&
  printf '%10000s' | sed 's/ /\0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >theinput &&
  nfcycler 24 --count --bufsize 20000 <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter works with any letter (e.g. "a")' "
  echo test not implemented yet
  test 1 = 2
"

test_expect_success '--delimiter works with any number (e.g. "0")' "
  echo test not implemented yet
  test 1 = 2
"

test_expect_success '--delimiter works with a string (e.g. "abcde")' "
  echo test not implemented yet
  test 1 = 2
"

test_expect_success '--delimiter complains about missing arg' "
  test_must_fail nfcapfps 24 --delimiter
"

test_done

# vi: set ft=sh :
