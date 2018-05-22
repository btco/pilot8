#!/usr/bin/perl
## Syntax: inject.pl [-r] cart.p8 source.lua [header.txt]
##
##   Injects the code from source.lua into the given Pico8 cartridge file.
##   The original code in the cart is discarded.
##   Supports basic preprocessing on the source file to reduce size.
##
##     -r: release build (doesn't preserve line numbers)

$remove_empty_lines=0;

if ($ARGV[0] eq "-r") {
  $remove_empty_lines=1;
  shift;
}

if (@ARGV < 2) {
  exec "grep ^## $0 | cut -c 4-"
}

$cart_file = shift;
$lua_file = shift;
$header_file = shift;

if (!(-f $lua_file)) {
  print STDERR "Can't find source: $lua_file\n";
  exit 1;
}

if (!(-f $cart_file)) {
  print STDERR "Can't find cart: $cart_file\n";
  exit 1;
}

$lua_file =~ /[.]lua$/ or die "Source file must be a .lua file.\n";
$cart_file =~ /[.]p8$/ or die "Cart file must be a .p8 file.\n";

print STDERR "Source file: $lua_file\n";
print STDERR "Cart file: $cart_file\n";

# Write a backup
system "cp -vf $cart_file $cart_file.bak";

# Read the full contents of source and cart.
$code = lc(qx(cat "$lua_file"));
$cart = qx(cat "$cart_file");

if (!($cart =~ /^(.*?)__lua__(.*?)__(.*)$/s)) {
  print STDERR "Error: cart contents did not match.\n";
  exit 2;
}

# Part of cartridge that comes before the code.
$pre_code = "$1\n__lua__\n";
# Part of cartridge that comes after the code.
$post_code = "__$3";

# Strip comments but leave blank lines so we don't lose line numbering.
$len_before = length($code);
$code =~ s/ *--.*$//mg;

# Get all #define directives.
while ($code =~ /^[#]define\s+(\S+)\s+(.*?)$/mg) {
  $defines{$1} = $2;
  print STDERR "Define: $1 -> $2\n";
}

# Expand '#define' constants
$iters=0;
while (1) {
  $iters++;
  die "Recursion too deep. Do you have circular #defines?" if $iters>100;
  $code_before = $code;
  foreach $k (keys(%defines)) {
    $v = $defines{$k};
    $code =~ s/\b$k\b/$v/g;
  }
  # If we didn't expand anything, it's time to stop.
  last if $code_before eq $code;
}

# Remove #define lines
$code =~ s/^#define.*?$//mg;

# Remove empty lines, if requested.
if ($remove_empty_lines) {
  print STDERR "Removing empty lines.\n";
  $code =~ s/\r//g;
  $code =~ s/^\s+$//mg;
  $code =~ s/\n+/\n/sg;
}

if ($header_file ne "") {
  $code = qx(cat "$header_file") . "\n$code";
}

$len_after = length($code);

print STDERR "Orig code size: $len_before\n";
print STDERR "Stripped size:  $len_after\n";

# Write out the cart with the new code.
open OUT, ">$cart_file" or die "Failed to write $cart.\n$!\n";
print OUT "$pre_code$code$post_code";
close OUT;

print STDERR "Wrote $cart_file.\n";

