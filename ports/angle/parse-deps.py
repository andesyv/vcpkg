# Tiny hacky script that interprets a DEPS file and attempts to extract dependencies

from importlib.util import spec_from_file_location, module_from_spec
from importlib.machinery import SourceFileLoader
import importlib.util
from pathlib import Path
import sys
from os import getcwd, path
import json
from argparse import ArgumentParser
import re

if __name__ != "__main__":
  sys.exit(1)

args_parser = ArgumentParser(description='Parses a DEPS file')
args_parser.add_argument('deps_file', help='path to DEPS file', metavar='deps-file', nargs='?')
args_parser.add_argument('--variables-file', help="path to variables file (if file doesn't exist, the script will create it)")
args_parser.add_argument('--verbose', help='print verbose output', action='store_true')
args_parser.add_argument('--vars', nargs='*', help='additional input variables that should impact parsing, formatted as var1=value1 var2=value2 ...')
args = args_parser.parse_args()

# Define some dummy functions for module parsing
def Str(var):
  return var

def get_variables():
  variables = None
  if args.variables_file and path.exists(args.variables_file):
    with open(args.variables_file, 'r') as f:
      variables = json.load(f)
    
  if variables is None:
    variables = DEPS.vars

  # Variables provided on command  line overrides whatever is fetched from variable file / DEPS file
  if args.vars:
    for var in args.vars:
      key, value = var.split('=')
      variables[key] = str(value)

  return variables


def Var(var):
  variables = get_variables()

  if var in variables:
    return variables[var]
  
def replace_var_or_default(var, default):
  # Reserved keywords that shouldn't be replaced:
  keywords = ['and', 'or', 'not', '==', '!=', '>=', '<=', '>', '<', 'is', 'True', 'False', 'None']
  if var in keywords:
    return var

  maybe_var = Var(var)
  # If the first variable substitution failed, the variable likely isn't define.
  # If so, return str(False) as a default
  if maybe_var is None:
    return default
  
  # Variable substitution can happen in a loop...
  previous_var = maybe_var
  while maybe_var is not None:
    previous_var = maybe_var
    maybe_var = Var(maybe_var)

  if previous_var is None:
    raise ValueError(f"Variable previous_var is suddenly None, which it wasn't previously.")
  
  # Interpret as value or string based on whether it's a keyword or not
  # return str(previous_var) if previous_var in keywords else f'"{previous_var}"'
  return str(previous_var)

def substitute_and_split_url(url):
  url = re.sub(r'\{[^\n\s\}]+\}', lambda x : replace_var_or_default(x.group(0)[1:-1], ''), url)
  parts = url.split('@')
  if len(parts) < 2:
    return None
  return parts[0], parts[1]

# globals()['Str'] = Str

# Import DEPS file as module
# https://stackoverflow.com/questions/67631/how-can-i-import-a-module-dynamically-given-the-full-path
depsPath = path.join(getcwd(), args.deps_file if args.deps_file else 'DEPS')
# loader = SourceFileLoader('DEPS', depsPath)
# lazyLoader = importlib.util.LazyLoader(loader)
# spec = importlib.util.spec_from_loader('DEPS', lazyLoader)
# if not spec:
#   raise ImportError(f'Cannot find DEPS file (at {depsPath})')

# DEPS = importlib.util.module_from_spec(spec)
# lazyLoader.exec_module(DEPS)
spec = importlib.util.spec_from_loader('DEPS', loader=None)
DEPS = importlib.util.module_from_spec(spec)
DEPS.Str = Str
DEPS.Var = Var
depsSource = Path(depsPath).read_text(encoding='utf8')
# depsSource = re.sub(r'Str\(.*\)', "''", depsSource)
# depsSource = re.sub(r'Var\(.*\)', '"Dummy_var_to_be_replaced"', depsSource)
exec(depsSource, DEPS.__dict__)
sys.modules['DEPS'] = DEPS

variables = get_variables()

if args.variables_file and not path.exists(args.variables_file):
  with open(args.variables_file, 'w') as f:
    json.dump(variables, f)

formatted_dependencies = []

# Bring all variables into global scope

# for key, value in variables.items():
#   globals()[key] = value

# Parse variables in deps dictionary
for key, value in DEPS.deps.items():
  # Perform variable substitution in conditions
  if 'condition' in value:
    # new_condition = ' '.join([ replace_var_or_default(term, str(False)) for term in value['condition'].split(' ') ])
    condition = value['condition']
    try:
      result = eval(condition, variables)
      if not result:
        continue
    except Exception as e:
      if args.verbose:
        print(f'ERROR: Failed to evaluate "{condition}": err: {e}')
      continue

  if 'url' in value:
    url, ref = substitute_and_split_url(value['url'])
    if url is None:
      continue
    
    formatted_dependencies.append({ 'dir': key, 'url': url, 'ref': ref })

print(json.dumps(formatted_dependencies, indent=2))
