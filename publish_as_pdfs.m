% Publish all files *.m as PDF files.

% You generally won't need to use this script.
% It produces a PDF printout of each .m file and saves it in a directory named html/

m_files = ["test_ServiceQueue", "Customer", ...
    "Event", "Arrival", "Departure", "RecordToLog", ...
    "ServiceQueue", "served_customer_times"];
for j = 1:length(m_files)
    in_file = sprintf("%s.m", m_files(j));
    if in_file ~= "publish_as_pdfs.m"
        display(in_file);
        publish(in_file, format="pdf", evalCode=false);
        publish(in_file, format="html", evalCode=false);
    end
end
