{ lib
, pkgs
, my_python
#, parliament
#, mindwm-sdk-python
}:
with pkgs;

python3.pkgs.buildPythonApplication {
  pname = "mindwm-knfunc";
  version = "0.1.0";

  src = ./.;

#  python = my_python;
  propagatedBuildInputs = [ my_python ];
#  buildInputs = [ my_python ];
#  dependencies = [
#    parliament
#    mindwm-sdk-python
#  ];

  pythonImportsCheck = [
    "knfunc"
    "parliament"
    "neo4j"
    "neomodel"
    "yaml"
  ];
  format = "pyproject";
  nativeBuildInputs = with python3.pkgs; [ setuptools ];
}
