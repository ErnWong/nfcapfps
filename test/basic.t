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
  nfcapfps --count 24 3>actual &&
  test_cmp actual expected
"

test_expect_success '--count does not disturb stdout' "
  printf '%1000s' | sed 's/ /\$RANDOM\\n/g' >expected &&
  nfcapfps --count 24 >actual &&
  test_cmp actual expected
"

test_expect_success '--bufsize allows exact amount of large payloads be emitted' "
  echo 10 >expected &&
  printf '%10000s' | sed 's/ /0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >theinput &&
  nfcapfps 24 --count --bufsize 20000 <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--bufsize maintains accuracy of stdout' "
  printf '%10000s' | sed 's/ /0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >expected &&
  nfcapfps 24 --count --bufsize 20000 <theinput >actual &&
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
  nfcapfps 24 --group json --count <theinput | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--group maintains accuracy of stdout' "
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
  []' >expected &&
  nfcapfps 24 --group json --count <theinput >actual &&
  test_cmp actual expected
"

test_expect_success '--group csv emits exact amount of newline entries' "
  echo 10 >expected &&
  printf '%10000s' | sed 's/ /0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >theinput &&
  nfcapfps 24 --count --group csv <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter "\n" emits exact amount of newline entries' "
  echo 10 >expected &&
  printf '%10000s' | sed 's/ /0/g' >largeline &&
  printf '%10s' | sed \"s/ /\$(cat largeline)\\n/g\" >theinput &&
  nfcapfps 24 --count --delimiter \"\\n\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter works with any letter (e.g. "a")' "
  echo 6 > expected &&
  printf '123a456
  789
  999
  10a
  bcdeaa
  %10000s a
  %10000s a' >theinput &&
  nfcapfps 24 --count --delimiter \"a\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter count increments at 1st character of stream' "
  echo 1 > expected &&
  printf '123' >theinput &&
  nfcapfps 24 --count --delimiter \"a\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter count doesnt increment upon reaching delimiter' "
  echo 1 > expected &&
  printf '123a' >theinput &&
  nfcapfps 24 --count --delimiter \"a\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter count increments at 1st character after delimiter' "
  echo 2 > expected &&
  printf '123a1' >theinput &&
  nfcapfps 24 --count --delimiter \"a\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter works with any number (e.g. "0")' "
  echo 6 > expected &&
  printf '1230456
  789
  999
  110
  bcde00
  %10000s 0
  %10000s 0' >theinput &&
  nfcapfps 24 --count --delimiter \"0\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter works with a string (e.g. "abcde")' "
  echo 6 > expected &&
  printf '123abcde456
  789abc
  de999
  10abcde
  bcdeabcdeabcde
  %10000s abcde
  %10000s abcde' >theinput &&
  nfcapfps 24 --count --delimiter \"abcde\" <theinput 3>&1 | tail -n1 >actual &&
  test_cmp actual expected
"

test_expect_success '--delimiter complains about missing arg' "
  test_must_fail nfcapfps 24 --delimiter
"

test_expect_success 'complains when both --delimiter and --group are supplied' "
  test_expect_code 64 nfcapfps 24 --delimiter ',' --group json
"

test_done

# vi: set ft=sh :
