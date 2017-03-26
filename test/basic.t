#!/bin/sh

test_description='Test basic functionality'

. ./sharness.sh

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

test_expect_success 'reject fps of inf - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps inf
"

test_expect_success 'reject fps of -ve - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps -35
"

test_expect_success 'reject non number fps - exit(EX_USAGE)' "
  test_expect_code 64 nfcapfps wat
"

test_expect_success 'writes correct output' "
  seq -999 999 >expected &&
  while read line; do echo \$line; done <expected | nfcapfps >actual &&
  test_cmp actual expected
"

test_expect_success 'does not send too early' "
  echo test not implemented yet &&
  test 1 = 2
"

test_expect_success 'supports float as fps arg' "
  echo test not implemented yet &&
  test 1 = 2
"

test_expect_success '--bufsize sets buffer size correctly' "
  echo test not implemented yet &&
  test 1 = 2
"

test_expect_success '--bufsize complains about missing number' "
  test_must_fail nfcapfps 24 --bufsize
"

test_done

# vi: set ft=sh :
