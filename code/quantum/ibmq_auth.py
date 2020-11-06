from qiskit import IBMQ
import os
token =os.environ.get('IBMQ_TOKEN')
token ='c07613170b2a5db540a401be985c08b86382e49be04a7d23cea6107180ab3f90765f685a6f0ab6d4c5462fc51e4091b0b9ced4cfa6539c286303e1f2c30e4362'
print(token)
IBMQ.save_account(token)
