#!/usr/bin/perl

use Digest::MD5 qw(md5_hex);

sub tokenizeName($){
    $n = shift;
    $n =~ s/[çÇ]/c/ig;
    $n =~ s/[éèëêÉÈËÊ]/e/ig;
    $n =~ s/[àäâÀÄÂ]/a/ig;
    $n =~ s/[ïîÏÎ]/i/ig;
    $n =~ s/[ùüûÙÜÛ]/u/ig;
    $n =~ s/[ôöÔÖ]/o/ig;
    $n =~ s/[ÿŷŸŶ]/y/ig;
    $n =~ s/[^a-z]/ /ig;
    $n = uc($n);
    $n =~ s/(^|\s)(\S{1,2}|IDE|MADAME|MONSIEUR|DOCTEUR|PROFESSEUR|INFIRMIER|DRS)(\s|$)/ /g;
    $n =~ s/  */ /ig;
    $n =~ s/^ //ig;
    $n =~ s/ $//ig;
    @n = split / /, $n;
    if ($n[0] eq $n[($#n + 1)/2]) {
	$n = '';
	for ($i = 0 ; $i < ($#n + 1)/2 ; $i++) {
	    $n .= $n[$i].' ';
	}
	chop($n);
    }
    return $n;
}
sub associateNameCP($$) {
    $n = shift;
    $cp = shift;
    $cp =~ s/^(\d{2}).*/\1/;
    return $n." - ".$cp;
}
sub tokenizeNameCP($$){
    $n = tokenizeName(shift);
    return associateNameCP($n, shift);
}
sub trymatches($$) {
    $n = shift;
    $t = tokenizeName($n);
    $cp = shift;
    @t = split / /, $t;
    for ($i = 0 ; $i <= $#t ; $i++) {
	$id = associateNameCP(join( ' ',@t), $cp);
	return $id if($id2rpps{$id});
	return $id if($id2names{$id});
	push(@t, shift(@t));
    }
    $id2names{$id} = $n;
    return ;
}

$file = shift;

#extract RPPS
open FILE, $file;
while(<FILE>) {
    @l = split /,/;
    $id = '';
    if ($l[7] > 10000000000 && $l[7] < 99999999999 && $l[3] && $l[4]) {
	$l[7] =~ s/\.0//;
	$id = tokenizeNameCP($l[3], $l[4]);
	if ($id && !$rpps{$id}) {
	    $id2rpps{$id} = $l[7];
	    $id2names{$id} = $l[3];
	    $rpps2id{$l[7]} = $id;
	}
    }
}
close FILE;

#search for matches
open FILE, $file;
$_ = <FILE>;
chomp;
print;
print ",BENEF_PS_HASH,BENEF_PS_DEPARTEMENT\n";
while(<FILE>){
    chomp;
    $id = '';
    @l = split /,/;
    next if (!$l[7] && !$l[3]);
    $l[7] =~ s/\.0//;
    if ($l[7] && $rpps2id{$l[7]}) {
	$id = $rpps2id{$l[7]};
    }
    $id = trymatches($l[3], $l[4]) unless ($id);
    if ($id) {
	$l[7] = $id2rpps{$id};
	$l[3] = $id2names{$id};
    }
    if ($l[4]) {
	$l[15] = $l[4];
	$l[15] =~ s/^(\d{2}).*/\1/;
    }
    if ($l[7] > 10000000000 && $l[7] < 99999999999) {
	$l[14] = md5_hex("RPPS:".$l[7]);
    }else{
	$l[7] = '';
	$l[14] = md5_hex("NOM/DEP:".$l[3].$l[4]);
	
    }
    print join(',',@l)."\n";
}