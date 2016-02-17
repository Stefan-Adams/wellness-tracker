package BNT::Wellness::Model::KV::Measurements;
use BNT::Wellness::Model::KV -base; # or use BNT::Wellness::Model 'BNT::Wellness::Model:KV' ?

col [qw(uid date k v)];

1;

__DATA__
@@ first_or_last_bmi.sql.ep
% $query->bind([$period->start, $period->end, $period->start, $period->end]);
select *,((weight*703)/(height*height)) v
  from (select uid,last_name,first_name,$agg(date) date,v weight from measurements left join participants using (uid) where k='weight' and date >= ? and date < ? group by uid order by last_name) a
  left join (select uid,$agg(date) date,v height from measurements left join participants using (uid) where k='height' and date >= ? and date < ? group by uid order by last_name) b
  using (uid)
