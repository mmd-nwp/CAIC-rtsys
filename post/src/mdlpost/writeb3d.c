#include "stdio.h"
#include <stdlib.h>
#include "grads.h"
 
int writeb3d_(int *nzp, int *nxp, int *nyp, float *array, char *fname, int *new)
{
  
         FILE *f1;
	 int i,j,k,point,icheck,size;
     
     
     size=(*nxp)*(*nyp)*(*nzp);
     
/* let's open the binary file */
   if (*new==1) {
      f1=fopen(fname,"wb");
   } else {
      f1=fopen(fname,"ab"); 
   }
   if (f1==NULL) {
      printf("\n error opening file \n");
      exit(-1);
   }
   fwrite(array,sizeof(float),size,f1);
   fclose(f1);
   return;
}
