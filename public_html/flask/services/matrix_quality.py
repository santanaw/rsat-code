from flask import Flask, jsonify, abort, request, make_response, url_for
from flask_restplus import Resource, reqparse, fields
from werkzeug.datastructures import FileStorage
import yaml
from subprocess import check_output, Popen, PIPE
import os,sys,re
import requests

service_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(service_dir + '/../lib')
sys.path.append(service_dir + '/../')
import utils
from rest_server import app,api

tool = 'matrix-quality'
### Read parameters from yaml file
(descr, get_parser, post_parser) = utils.read_parameters_from_yml(api, service_dir+'/' + tool.replace('-','_') +'.yml')

ns = api.namespace(tool, description=descr)

################################################################
### Get information about polymorphic variations
@ns.route('/',methods=['POST','GET'])
class MatrixQuality(Resource):
	@api.expect(get_parser)
	def get(self):
    		data = get_parser.parse_args()
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
	
	def _run(self, data):
		output_choice = 'display'
		(boolean_var, fileupload_parameters) = utils.get_boolean_file_params(service_dir+'/' + tool.replace('-','_') +'.yml')
		exclude = fileupload_parameters + ['content-type']
		for x in fileupload_parameters:
			exclude = exclude + [x + '_string', x + '_string_type']
		# background model
		exclude += ['markov_order', 'org', 'seq_type', 'seq_type_2']
		command = utils.perl_scripts + '/' + tool
		result_dir = utils.make_tmp_dir(tool)
		
		for param in data:
		    if param in boolean_var:
		        if data[param] == True:
		            command += ' -' + param
		        elif data[param] == False:
		            continue
		    elif param == 'seq_type' and data[param] is not None and data[param] != '':
		        seq_file = utils.parse_fileupload_parameters(data, ['seq_file'], tool, result_dir, ',')
		        seq_file_ops = seq_file.strip().split(' ')
		        command += ' -seq ' + data['seq_type'] + ' ' + seq_file_ops[1]
		    elif param == 'seq_type_2' and data[param] is not None and data[param] != '':
		        seq_file = utils.parse_fileupload_parameters(data, ['seq_file_2'], tool, result_dir, ',')
		        seq_file_ops = seq_file.strip().split(' ')
		        command += ' -seq ' + data['seq_type_2'] + ' ' + seq_file_ops[1]
		    elif param == 'perm' and data[param] is not None and data[param] != '':
		        command += ' -perm ' + data['seq_type'] + ' ' + str(data[param])
		    elif param == 'plot' and data[param] is not None and data[param] != '':
		        command += ' -plot ' + data['seq_type'] + ' ' + data[param]
		    elif param == 'perm_2' and data[param] is not None and data[param] != '':
		        command += ' -perm ' + data['seq_type_2'] + ' ' + str(data[param])
		    elif param == 'plot_2' and data[param] is not None and data[param] != '':
		        command += ' -plot ' + data['seq_type_2'] + ' ' + data[param]
		    elif param == 'org' and data[param] is not None and data[param] != '':
		        len = 1
		        if 'markov_order' in data and data['markov_order'] is not None and data['markov_order'] != '':
		            len = data['markov_order'] + 1 
		        command += ' -bgfile ' + utils.get_backgroundfile(data['org'], len) + '.gz'
		    elif data[param] is not None and data[param] != '' and param not in exclude:
		        command += ' -' + param + ' ' + str(data[param])
		command += utils.parse_fileupload_parameters(data, ['m', 'ms', 'bgfile'], tool, result_dir, ',')		
		command += ' -o ' + result_dir + '/' + tool
		return utils.run_command_background(command, tool, result_dir, tool+'_synthesis.html')
