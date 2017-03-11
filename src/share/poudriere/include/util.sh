# Copyright (c) 2016 Bryan Drewery <bdrewery@FreeBSD.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

: ${ENCODE_SEP:=$'\002'}

# Encode $@ for later decoding
encode_args() {
	local -; set +x
	[ $# -ge 1 ] || eargs encode_args var_return [args]
	local var_return="$1"
	shift
	local _args lastempty

	_args=
	lastempty=0
	while [ $# -gt 0 ]; do
		_args="${_args}${_args:+${ENCODE_SEP}}${1}"
		[ $# -eq 1 -a -z "$1" ] && lastempty=1
		shift
	done
	# If the string ends in ENCODE_SEP then add another to
	# fix 'set' later eating it.
	[ ${lastempty} -eq 1 ] && _args="${_args}${_args:+${ENCODE_SEP}}"

	setvar "${var_return}" "${_args}"
}

# Decode data from encode_args
# Usage: eval $(decode_args data_var_name)
decode_args() {
	local -; set +x
	[ $# -eq 1 ] || eargs decode_args encoded_args_var
	local encoded_args_var="$1"

	# IFS="${ENCODE_SEP}"
	# set -- ${data}
	# unset IFS

	echo "IFS=\"\${ENCODE_SEP}\"; set -- \${${encoded_args_var}}; unset IFS"
}

# Read a file until 0 status is found. Partial reads not accepted.
read_line() {
	[ $# -eq 2 ] || eargs read_line var_return file
	local var_return="$1"
	local file="$2"
	local max_reads reads ret line

	ret=0
	line=

	if [ -f "${file}" ]; then
		max_reads=100
		reads=0

		# Read until a full line is returned.
		until [ ${reads} -eq ${max_reads} ] || \
		    read -t 1 -r line < "${file}"; do
			sleep 0.1
			reads=$((${reads} + 1))
		done
		[ ${reads} -eq ${max_reads} ] && ret=1
	else
		ret=1
	fi

	setvar "${var_return}" "${line}"

	return ${ret}
}
