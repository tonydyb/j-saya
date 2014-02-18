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


VALUE StockAnalizer_make_saya_history(VALUE self, VALUE a, VALUE b, VALUE m_, VALUE n_) {
  int jda,jdb,xa,xb,lena,lenb,
      m=NUM2INT(m_),n=NUM2INT(n_),nb=0;
  VALUE *pa,*pb,*ppa,*ppb;

  lena = RARRAY_LEN(a);
  lenb = RARRAY_LEN(b);

  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);

  ppa = pa + lena;
  ppb = pb + lenb;

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
        nb++;
        pa++,pb++;
     }
  }

  if (!nb) {
    rb_raise(rb_eRangeError,
        "no date");
  }
  
  VALUE history = rb_ary_new2(nb), cmpo;

  nb = 0;
  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);
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

        cmpo = rb_ary_new2(2);
        rb_ary_store(cmpo,0,INT2NUM(jda));
        rb_ary_store(cmpo,1,INT2NUM(xa*m-xb*n));
        rb_ary_store(history,nb,cmpo);
        
        nb++; 
        pa++,pb++;
     }
  }

  return history;
}

VALUE StockAnalizer_make_kaisa_histores(VALUE self, VALUE a, VALUE b) {
  int jda,jdb,jjdab,xa,xb,xxa,xxb,lena,lenb,first=1,nb=0,jumpa=0,jumpb=0;
  VALUE *pa,*pb,*ppa,*ppb;

  lena = RARRAY_LEN(a);
  lenb = RARRAY_LEN(b);

  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);

  ppa = pa + lena;
  ppb = pb + lenb;

  while(pa < ppa && pb < ppb) {
     jda = NUM2INT(RARRAY_PTR(*pa)[0]);
     jdb = NUM2INT(RARRAY_PTR(*pb)[0]);
     if (jda < jdb) {
       pa++;
       jumpa++;
       continue;
     }
     else if (jda > jdb) {
       pb++;
       jumpb++;
       continue;
     }
     else {
        if (first) {
          first = 0;
        }
        else if (jumpa == 1 && jumpb == 1) { 
          nb++;
        }
        jumpa = jumpb = 1;
        pa++,pb++;
     }
  }

  if (!nb) {
    rb_raise(rb_eRangeError,
        "no date");
  }

  VALUE history[] = {rb_ary_new2(nb), rb_ary_new2(nb)}, cmpo;

  first = 1;
  nb = 0;
  jumpa = jumpb = 0;

  pa = RARRAY_PTR(a);
  pb = RARRAY_PTR(b);
  while(pa < ppa && pb < ppb) {
     jda = NUM2INT(RARRAY_PTR(*pa)[0]);
     jdb = NUM2INT(RARRAY_PTR(*pb)[0]);
     if (jda < jdb) {
       pa++;
       jumpa++;
       continue;
     }
     else if (jda > jdb) {
       pb++;
       jumpb++;
       continue;
     }
     else {
         xa = NUM2INT(RARRAY_PTR(*pa)[1]);
         xb = NUM2INT(RARRAY_PTR(*pb)[1]);
        if (first) {
          first = 0;
        }
        else if (jumpa == 1 && jumpb == 1) { 
          cmpo = rb_ary_new2(2);
          rb_ary_store(cmpo,0,INT2NUM(jda));
          rb_ary_store(cmpo,1,INT2NUM(xa-xxa));
          rb_ary_store(history[0],nb,cmpo);

          cmpo = rb_ary_new2(2);
          rb_ary_store(cmpo,0,INT2NUM(jdb));
          rb_ary_store(cmpo,1,INT2NUM(xb-xxb));
          rb_ary_store(history[1],nb,cmpo);
          
          nb++;
          
        }
        
        xxa = xa;
        xxb = xb;
        jumpa = jumpb = 1;
        pa++,pb++;
    } 
  }

  return rb_ary_new4(2,history);
}

VALUE StockAnalizer_make_mva_history(VALUE self, VALUE a, VALUE period_) {
  int i,j,k,jd,x,len,period;
  double ave; 
  VALUE *p;

  len = RARRAY_LEN(a);

  if (!len) {
    rb_raise(rb_eRangeError,
        "no sufficient array length");
  }

  period = NUM2INT(period_);
  p = RARRAY_PTR(a);


  VALUE history= rb_ary_new2(len-period+1), cmpo;
  
  for (i = period-1,j=0 ; i < len ; i++,j++) {
    ave = 0; 
    for (k = j ; k <= i ; k++) {
      x = NUM2INT(RARRAY_PTR(p[k])[1]);
      ave += x;
    }
    ave /= period;
    jd = NUM2INT(RARRAY_PTR(p[i])[0]);
    
    cmpo = rb_ary_new2(2);
    rb_ary_store(cmpo,0,INT2NUM(jd));
    rb_ary_store(cmpo,1,INT2NUM(ave));
    rb_ary_store(history,j,cmpo);
  }

  return history;
  
}

VALUE StockAnalizer_make_sigma_history(VALUE self, VALUE a, VALUE period_) {
  int i,j,k,jd,x,len,period;
  double ave,z; 
  VALUE *p;

  len = RARRAY_LEN(a);

  if (!len) {
    rb_raise(rb_eRangeError,
        "no sufficient array length");
  }

  period = NUM2INT(period_);
  p = RARRAY_PTR(a);


  VALUE history= rb_ary_new2(len-period+1), cmpo;
  
  for (i = period-1,j=0 ; i < len ; i++,j++) {
    ave = 0; 
    for (k = j ; k <= i ; k++) {
      x = NUM2INT(RARRAY_PTR(p[k])[1]);
      ave += x;
    }
    ave /= period;
    z = 0;
    for (k = j ; k <= i ; k++) {
      x = NUM2INT(RARRAY_PTR(p[k])[1]);
      z += (x-ave)*(x-ave);
    }
    jd = NUM2INT(RARRAY_PTR(p[i])[0]);
    z = sqrt(z/period);
    
    cmpo = rb_ary_new2(2);
    rb_ary_store(cmpo,0,INT2NUM(jd));
    rb_ary_store(cmpo,1,INT2NUM(z));
    rb_ary_store(history,j,cmpo);
  }

  return history;
}

VALUE StockAnalizer_make_bollinger_bands(VALUE self, VALUE mva, VALUE sigma, VALUE c_) {
  int jda,jdb,xa,xb,lena,lenb,c,nb=0;
  VALUE *pa,*pb,*ppa,*ppb;

  c = NUM2INT(c_);

  lena = RARRAY_LEN(mva);
  lenb = RARRAY_LEN(sigma);

  pa = RARRAY_PTR(mva);
  pb = RARRAY_PTR(sigma);

  ppa = pa + lena;
  ppb = pb + lenb;

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
        nb++;
        pa++,pb++;
     }
  }

  if (!nb) {
    rb_raise(rb_eRangeError,
        "no date");
  }
  
  VALUE history[] = {rb_ary_new2(nb),rb_ary_new2(nb)}, cmpo;

  nb = 0;
  pa = RARRAY_PTR(mva);
  pb = RARRAY_PTR(sigma);
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

        cmpo = rb_ary_new2(2);
        rb_ary_store(cmpo,0,INT2NUM(jda));
        rb_ary_store(cmpo,1,INT2NUM(xa-c*xb));
        rb_ary_store(history[0],nb,cmpo);
        
        cmpo = rb_ary_new2(2);
        rb_ary_store(cmpo,0,INT2NUM(jda));
        rb_ary_store(cmpo,1,INT2NUM(xa+c*xb));
        rb_ary_store(history[1],nb,cmpo);

        nb++; 
        pa++,pb++;
     }
  }

  return rb_ary_new4(2,history);
}

void Init_stock_analyzer() {
  VALUE module;

  module = rb_define_module("StockAnalyzer");
  rb_define_module_function(module, "correl",StockAnalizer_correl, 2);
  rb_define_module_function(module, "make_saya_history",
          StockAnalizer_make_saya_history,4);
  rb_define_module_function(module, "make_kaisa_histories",
          StockAnalizer_make_kaisa_histores,2);
  rb_define_module_function(module, "make_mva_history",
          StockAnalizer_make_mva_history,2);
  rb_define_module_function(module, "make_sigma_history",
          StockAnalizer_make_sigma_history,2);
  rb_define_module_function(module, "make_bollinger_bands",
          StockAnalizer_make_bollinger_bands,3);
  rb_define_module_function(module, "align",
          StockAnalizer_make_bollinger_bands,3);

}



