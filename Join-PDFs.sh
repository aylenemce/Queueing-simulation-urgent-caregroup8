#!/bin/bash

# This is a script I use to join files produced by publish_as_pdfs.m into one printout.
# You generally won't need to use it.

cd 'html'

pdfjam -o 'Queueing-simulation-printout.pdf' \
       test_ServiceQueue.pdf \
       Run_ServiceQueue.pdf \
       Customer.pdf \
       Event.pdf \
       Arrival.pdf \
       Departure.pdf \
       RecordToLog.pdf \
       ServiceQueue.pdf \
       served_customer_times.pdf
