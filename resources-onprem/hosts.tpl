[jenkins]
%{ for ip in jenkins ~}
${ip}
%{ endfor ~}
