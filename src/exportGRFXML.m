function exportGRFXML(xmlFilename,motFilename,outputMotionFolder)

fid = fopen(fullfile(outputMotionFolder,xmlFilename),'w');

fprintf(fid,'<?xml version="1.0" encoding="UTF-8" ?>\n');
fprintf(fid,'<OpenSimDocument Version="40000">\n');
fprintf(fid,'\t<ExternalLoads name="externalloads">\n');

fprintf(fid,'\t\t<objects>\n');
fprintf(fid,'\t\t\t<ExternalForce name="externalforce">\n');

fprintf(fid,'\t\t\t\t<applied_to_body>Toes_r</applied_to_body>\n');
fprintf(fid,'\t\t\t\t<force_expressed_in_body>ground</force_expressed_in_body>\n');
fprintf(fid,'\t\t\t\t<point_expressed_in_body>ground</point_expressed_in_body>\n');

fprintf(fid,'\t\t\t\t<force_identifier>x1_ground_force_v</force_identifier>\n');
fprintf(fid,'\t\t\t\t<point_identifier>x1_ground_force_p</point_identifier>\n');
fprintf(fid,'\t\t\t\t<torque_identifier>x1_ground_torque_</torque_identifier>\n');

fprintf(fid,'\t\t\t\t<data_source_name>mouse_grf</data_source_name>\n');

fprintf(fid,'\t\t\t</ExternalForce>\n');
fprintf(fid,'\t\t</objects>\n');

fprintf(fid,'\t\t<groups />\n');

motFileLine = strcat('\t\t<datafile>',motFilename,'</datafile>\n');
fprintf(fid,motFileLine);

fprintf(fid,'\t</ExternalLoads>\n');
fprintf(fid,'</OpenSimDocument>\n');

fclose(fid);

end