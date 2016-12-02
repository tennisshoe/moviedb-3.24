function [ output_args ] = cleanname( input_args )
%CLEANNAME Summary of this function goes here
%   Detailed explanation goes here

tokens = regexp(input_args,'^(.*?)\s*(?:\(|\[|#|$)','tokens');
output_args= tokens{1};
end

