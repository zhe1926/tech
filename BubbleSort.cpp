#include<iostream>
using namespace std;

void bubbleSort1(int A[],int n){
	for(int i=0;i<n-1;i++){
		for(int j=n-1;j>i;j--){
			if(A[j-1]>A[j]){
				swap(A[j-1],A[j]);
			}
		}
		cout<<"µÚ"<<(i+1)<<"ÌËÅÅÐò£º";
		for(int i=0;i<n;i++){
			cout<<A[i]<<" ";
		}
		cout<<endl;
	}
	
	cout<<"×îÖÕË³Ðò£º";
	for(int i=0;i<n;i++){
		cout<<A[i]<<" ";
	}
	
}

int main(){
	int A[]={3,2,4,1,5,6};
	bubbleSort1(A,6);
}