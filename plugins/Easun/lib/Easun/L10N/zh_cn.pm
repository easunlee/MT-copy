# EasunStudio plugin for Movable Type
# Author: EasunLee (http://easun.org)
# Released under the Artistic License
#
# $Id: zh_cn.pm  EasunLee (http://easun.org) $

package Easun::L10N::zh_cn;

use strict;
use base 'Easun::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
    'RandInclude' => '随机模块加载插件',
    'SimpleComment' => 'SimpleComment简易轻量级评论防SPAM插件' ,
    'EasunLee' => '路杨(EasunLee)',
    'Adds template tags as <$MTRandInclude module="xxx,yyy,zzz" $>. Load Random template modules when rebuilding templates.' => '此插件将添加一个模板标签<$MTRandInclude module="xxx,yyy,zzz" $>，让系统随机加载一个模块。',
    'A Simple plugin for Anti-Comment-SPAM plugin for Movable Type By Easun.org' =>'一个简易轻量级的防止评论SPAM的插件，对用户完全透明，不需要输入什么验证码',
);

1;