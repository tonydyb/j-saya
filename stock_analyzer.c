#include <ruby.h>
#include <stdio.h>

VALUE StockAnalizer_correl(VALUE self, VALUE a, VALUE b) {

  int jda,jdb,xa,xb,lena,lenb;
  VALUE *pa,*pb,*ppa,*ppb;

  lena = RARRAY_LEN(a);
  lenb = RARRAY_LEN(b);

  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);

  ppa = pa + lena;
  ppb = pb + lenb;

  int nb = 0;
  double avea = 0, aveb = 0;
  while(pa < ppa && pb < ppb) {
     jda = NUM2INT(RARRAY_PTR(*pa)[0]);
     jdb = NUM2INT(RARRAY_PTR(*pb)[0]);
     if (jda < jdb) {
       pa++;
       continue;
     }
     else if (jda > jdb) {
       pb++;
       continue;
     }
     else {
        xa = NUM2INT(RARRAY_PTR(*pa)[1]);
        xb = NUM2INT(RARRAY_PTR(*pb)[1]);
        avea += xa;
        aveb += xb;
        nb++;
        pa++,pb++;
     }
  }

  if (nb <= 1) {
    rb_raise(rb_eRangeError,
        "no date");
  }

  avea /= nb;
  aveb /= nb;

  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);
  double num=0, dena=0, denb=0,tmpa,tmpb;
  while(pa < ppa && pb < ppb) {
     jda = NUM2INT(RARRAY_PTR(*pa)[0]);
     jdb = NUM2INT(RARRAY_PTR(*pb)[0]);
     if (jda < jdb) {
       pa++;
       continue;
     }
     else if (jda > jdb) {
       pb++;
       continue;
     }
     else {
        xa = NUM2INT(RARRAY_PTR(*pa)[1]);
        xb = NUM2INT(RARRAY_PTR(*pb)[1]);
        
        tmpa = xa-avea;
        tmpb = xb-aveb;

        num  += tmpa*tmpb;
        dena += tmpa*tmpa;
        denb += tmpb*tmpb;

        pa++,pb++;
     }
  }
  if (dena == 0 || denb == 0) {
    rb_raise(rb_eRangeError,
        "too small numerator");
  }

  return rb_float_new(num/(sqrt(dena)*sqrt(denb)));
}

void Init_stock_analyzer() {
  VALUE module;

  module = rb_define_module("StockAnalyzer");
  rb_define_module_function(module, "correl",StockAnalizer_correl, 2);
}



