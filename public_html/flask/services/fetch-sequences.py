from flask import Flask, jsonify, abort, request, make_response, url_for
from flask_restplus import Resource, reqparse, fields
from werkzeug.datastructures import FileStorage
import yaml
import os,sys,re
import requests

service_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(service_dir + '/../lib')
sys.path.append(service_dir + '/../')
import utils
from rest_server import app,api

tool = 'fetch-sequences'
(descr,get_parser,post_parser) = utils.read_parameters_from_yml(api,service_dir + '/' + tool.replace('-','_') + '.yml')

ns = api.namespace(tool, description=descr)

@ns.route('/', methods=['POST','GET'])
class FetchSequences(Resource):
    @api.expect(get_parser)
    def get(self):
        data = request.get_json(force=True) #get_parser.parse_args()
	if data['content-type'] == 'text/plain':
		resp = self._run(data)
		return utils.output_txt(resp,200)
	return self._run(data)
        
    @api.expect(post_parser)
    def post(self):
	data = []
	if request.headers.get('Content-type') == 'application/json':
		data = request.get_json(force=True)
	else:	
		data = post_parser.parse_args()
	return self._run(data)

    def _run(self,data):
        output_choice = 'display'
        command = utils.perl_scripts + '/' + tool
        result_dir = utils.make_tmp_dir(tool)
        (boolean_var, fileupload_parameters) = utils.get_boolean_file_params(service_dir+'/' + tool.replace('-','_') +'.yml')
        exclude = fileupload_parameters + ['content-type']
        
        for x in fileupload_parameters:
            exclude = exclude + [x + '_string', x + '_string_type']       
        for param in data:
            if data[param] is not None and data[param] != '' and param not in exclude:
                command += ' -' + param + ' ' + str(data[param])
        command += utils.parse_fileupload_parameters(data,fileupload_parameters,tool,result_dir,',')
        return utils.run_command(command, output_choice, tool, 'fasta', result_dir)
