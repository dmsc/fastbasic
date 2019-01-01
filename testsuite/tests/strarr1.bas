 DIM ar$(100)
 ar$(10) = "Some Text"
 ar$(30) = "More Text"
 for i=0 to 99
   if ar$(i) <> ""
     ? i ; ":"; ar$(i)
   endif
 next i
