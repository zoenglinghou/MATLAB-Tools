classdef estm
%ESTM Estimate Class
% Estm class contains the best estm value, the standard error,
% standard deviation, and sample size properties. Specified class values
% by:
% obj = estm(Val)
% Val is the best estm or data array/matrix.
%
% obj = estm(Val, SE)
% Val is the best estm or data array/matrix. SE is stanard erro.
%
% obj = estm(Val, Name, Value)
% Val is the best estm. It can only be a number.
% Name-Value pairs specify the standard error, standard deviation, and/or sample size. Only maximum of two pairs can be stated.
%
% Basic arithmnic calulations are overloaded. Complex functions can be
% overloaded with function estComp.m.
	properties
		Value@double
		Data@double
		StandardError@double
		StandardDeviation@double
		Size@double
	end
	methods

		% Set Value Functions
		function obj = estm(Val, varargin)
			p = inputParser;
			addRequired(p, 'Val', @isnumeric);
			addParameter(p, 'SE', [], @(x) isnumeric(x) && numel(x) == 1);
			addParameter(p, 'SD', [], @(x) isnumeric(x) && numel(x) == 1);
			addParameter(p, 'Size', [], @(x) ~mod(x, 1) && x > 0);
			parse(p, Val, varargin{:});

			% Best value manipulation
			if numel(p.Results.Val) == 1
				% If only best value is given
				obj.Data = [];
				obj.Value = p.Results.Val;
				results = struct2cell(p.Results);
				switch num2str(find(cellfun(@isempty, results(1:3)')))
					case '1' % If no SD
						obj.StandardError = p.Results.SE;
						obj.Size = p.Results.Size;
						obj.StandardDeviation = obj.StandardError / sqrt(obj.Size);
					case '2' % If no SE
						obj.Size = p.Results.Size;
						obj.StandardDeviation = p.Results.SD;
						obj.StandardError = obj.StandardDeviation / sqrt(obj.Size);
					case '1  3' % If SE only
						obj.StandardError = p.Results.SE;
					case '2  3' % If SD only
						obj.StandardDeviation = p.Results.SD;
					case '1  2  3' % None
						obj.StandardDeviation = 0;
						obj.StandardError = 0;
					case '3' % No Size
						obj.StandardDeviation = p.Results.SD;
						obj.StandardError = p.Results.SE;
					case '' % All three
						if p.Results.SE / p.Results.SD == sqrt(p.Results.Size)
							obj.StandardError = p.Results.SE;
							obj.Size = p.Results.Size;
							obj.StandardDeviation = p.Results.SD;
						else
							error('Relationships between uncertainties cannot be established.');
						end
					otherwise
						error('Parameters invalid');
				end
			else
				if nargin ~= 1
					% If data is stated
					error('When data is stated, no other parameters are allowed.');
				end
				obj.Size = numel(p.Results.Val);
				obj.Data = p.Results.Val;
				obj.Value = mean(p.Results.Val);
				obj.StandardDeviation = std(p.Results.Val);
				obj.StandardError = obj.StandardDeviation / sqrt(obj.Size);
			end
		end

		% Overloading Functions
		function output = plus(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 + obj2, obj1, obj2);
		end
		function output = minus(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 - obj2, obj1, obj2);
		end
		function output = mtimes(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 * obj2, obj1, obj2);
		end
		function output = mrdivide(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 / obj2, obj1, obj2);
		end
		function output = mldivide(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 \ obj2, obj1, obj2);
		end
		function output = mpower(obj1, obj2)
			output = estComp(@(obj1, obj2) obj1 ^ obj2, obj1, obj2);
		end
		function output = sqrt(obj)
			output = estComp(@(obj) sqrt(obj), obj);
		end
		function output = uplus(obj)
			output = obj;
		end
		function output = uminus(obj)
			output = obj;
			output.Val = -output.Val;
		end
		function output = times(obj1, obj2)
			if numel(obj1) == numel(obj2)...
				&& (iscolumn(obj1) && iscolumn(obj2))...
				|| (isrow(obj1) && isrow(obj2))
					output = arrayfun(@(x, y) estComp(@(x, y) x * y, x, y),...
						obj1, obj2, 'UniformOutput', 0);
			elseif (iscolumn(obj1) && isrow(obj2))...
					|| (isrow(obj1) && iscolumn(obj2))
				output = arrayfun(@(x)...
							arrayfun(@(a, b)...
								estComp(@(a, b)...
									a * b,...
									a{:}, b),...
									cellfun(@(v)...
										x,...
										cell(numel(obj2), 1),...
										'UniformOutput', 0),...
									obj2,...
								'UniformOutput', 0),...
							obj1,...
							'UniformOutput', 0);
			else
				error('Matrix indices must match.');
			end
		end
		function output = rdivide(obj1, obj2)
			if numel(obj1) == numel(obj2)...
				&& (iscolumn(obj1) && iscolumn(obj2))...
				|| (isrow(obj1) && isrow(obj2))
					output = arrayfun(@(x, y) estComp(@(x, y) x / y, x, y),...
						obj1, obj2, 'UniformOutput', 0);
			elseif (iscolumn(obj1) && isrow(obj2))...
					|| (isrow(obj1) && iscolumn(obj2))
				output = arrayfun(@(x)...
							arrayfun(@(a, b)...
								estComp(@(a, b)...
									a / b,...
									a{:}, b),...
									cellfun(@(v)...
										x,...
										cell(numel(obj2), 1),...
										'UniformOutput', 0),...
									obj2,...
								'UniformOutput', 0),...
							obj1,...
							'UniformOutput', 0);
			else
				error('Matrix indices must match.');
			end
		end
		function output = ldivide(obj1, obj2)
			if numel(obj1) == numel(obj2)...
				&& (iscolumn(obj1) && iscolumn(obj2))...
				|| (isrow(obj1) && isrow(obj2))
					output = arrayfun(@(x, y) estComp(@(x, y) x \ y, x, y),...
						obj1, obj2, 'UniformOutput', 0);
			elseif (iscolumn(obj1) && isrow(obj2))...
					|| (isrow(obj1) && iscolumn(obj2))
				output = arrayfun(@(x)...
							arrayfun(@(a, b)...
								estComp(@(a, b)...
									a \ b,...
									a{:}, b),...
									cellfun(@(v)...
										x,...
										cell(numel(obj2), 1),...
										'UniformOutput', 0),...
									obj2,...
								'UniformOutput', 0),...
							obj1,...
							'UniformOutput', 0);
			else
				error('Matrix indices must match.');
			end
		end
		function output = power(obj1, obj2)
			if numel(obj1) == numel(obj2)...
				&& (iscolumn(obj1) && iscolumn(obj2))...
				|| (isrow(obj1) && isrow(obj2))
					output = arrayfun(@(x, y) estComp(@(x, y) x ^ y, x, y),...
						obj1, obj2, 'UniformOutput', 0);
			elseif (iscolumn(obj1) && isrow(obj2))...
					|| (isrow(obj1) && iscolumn(obj2))
				output = arrayfun(@(x)...
							arrayfun(@(a, b)...
								estComp(@(a, b)...
									a ^ b,...
									a{:}, b),...
									cellfun(@(v)...
										x,...
										cell(numel(obj2), 1),...
										'UniformOutput', 0),...
									obj2,...
								'UniformOutput', 0),...
							obj1,...
							'UniformOutput', 0);
			else
				error('Matrix indices must match.');
			end
		end
		function output = eq(obj1, obj2)
			% When only one of them is estm class
			if isa(obj1, 'estm') + isa(obj2, 'estm') == 1
				if ~isa(obj1, 'estm')
					buffer = obj1;
					obj1 = obj2;
					obj2 = buffer;
					clear(buffer);
				end
				if isempty(obj1.Size) || isempty(obj1.StandardDeviation)
					error('Estm class must have sample size and standard deviatin for t-test');
				end
				if isempty(obj1.Data)
					t = abs((obj1.Value - obj2) / obj1.StandardError);
					output = 1 - tcdf(t, obj1.Size - 1);
				else
					[~, output] = ttest(obj1.Data, obj2);
				end
			else % 2-sample t-test
				[~, output] = ttest2(obj1.Data, obj2.Data);
			end
		end
		function output = gt(obj1, obj2)
			% When only one of them is estm class
			if isa(obj1, 'estm') + isa(obj2, 'estm') == 1
				if ~isa(obj1, 'estm')
					buffer = - obj1;
					obj1 = - obj2;
					obj2 = buffer;
					clear(buffer);
				end
				if isempty(obj1.Size) || isempty(obj1.StandardDeviation)
					error('Estm class must have sample size and standard deviatin for t-test');
				end
				if isempty(obj1.Data)
					t = (obj1.Value - obj2) / obj1.StandardError;
					output = tcdf(t, obj1.Size - 1);
				else
					[~, p] = ttest(obj1.Data, obj2, 'Tail', 'right');
					output = 1 - p;
				end
			else % 2-sample t-test
				[~, output] = ttest2(obj1.Data, obj2.Data, 'Tail', 'right');
			end
		end
		function output = ge(obj1, obj2)
			% When only one of them is estm class
			if isa(obj1, 'estm') + isa(obj2, 'estm') == 1
				if ~isa(obj1, 'estm')
					buffer = - obj1;
					obj1 = - obj2;
					obj2 = buffer;
					clear(buffer);
				end
				if isempty(obj1.Size) || isempty(obj1.StandardDeviation)
					error('Estm class must have sample size and standard deviatin for t-test');
				end
				if isempty(obj1.Data)
					t = (obj1.Value - obj2) / obj1.StandardError;
					output = tcdf(t, obj1.Size - 1);
				else
					[~, p] = ttest(obj1.Data, obj2, 'Tail', 'right');
					output = 1 - p;
				end
			else % 2-sample t-test
				[~, output] = ttest2(obj1.Data, obj2.Data, 'Tail', 'right');
			end
		end
		function output = lt(obj1, obj2)
			% When only one of them is estm class
			if isa(obj1, 'estm') + isa(obj2, 'estm') == 1
				if ~isa(obj1, 'estm')
					buffer = - obj1;
					obj1 = - obj2;
					obj2 = buffer;
					clear(buffer);
				end
				if isempty(obj1.Size) || isempty(obj1.StandardDeviation)
					error('Estm class must have sample size and standard deviatin for t-test');
				end
				if isempty(obj1.Data)
					t = - (obj1.Value - obj2) / obj1.StandardError;
					output = tcdf(t, obj1.Size - 1);
				else
					[~, p] = ttest(obj1.Data, obj2, 'Tail', 'left');
					output = 1 - p;
				end
			else % 2-sample t-test
				[~, output] = ttest2(obj1.Data, obj2.Data, 'Tail', 'left');
			end
		end
		function output = le(obj1, obj2)
			% When only one of them is estm class
			if isa(obj1, 'estiamte') + isa(obj2, 'estm') == 1
				if ~isa(obj1, 'estm')
					buffer = - obj1;
					obj1 = - obj2;
					obj2 = buffer;
					clear(buffer);
				end
				if isempty(obj1.Size) || isempty(obj1.StandardDeviation)
					error('Estm class must have sample size and standard deviation for t-test');
				end
				if isempty(obj1.Data)
					t = - (obj1.Value - obj2) / obj1.StandardError;
					output = tcdf(t, obj1.Size - 1);
				else
					[~, p] = ttest(obj1.Data, obj2, 'Tail', 'left');
					output = 1 - p;
				end
			else % 2-sample t-test
				[~, output] = ttest2(obj1.Data, obj2.Data, 'Tail', 'left');
			end
		end
	end
end

function [output] = estComp(func, varargin)
%ESTCOMP Computation on estm class
%   [output] = estComp(func, estm1, ..., estmN) performs
%   calculations with standard error. func is the function handle of the
%   calculation. estm1, ..., estmN are the estm class values.
%   Output is estm class.
assert(isa(func, 'function_handle'), 'Must enter a function handle.');
notEstIdx = find(cellfun(@(x) ~isa(x, 'estm'), varargin));
varargin(notEstIdx) = cellfun(@(x) estm(x, 'SE', 0, 'SD', 0),...
	varargin(notEstIdx), 'UniformOutput', 0);

% Input prcessing
var = cellfun(@(x) x.Value, varargin, 'UniformOutput', 0);
varSE = cellfun(@(x) x.StandardError, varargin, 'UniformOutput', 0);
varSD = cellfun(@(x) x.StandardDeviation, varargin,...
	'UniformOutput', 0);
% Replace empty SE/SD with 0
varSE(cellfun(@isempty, varSE)) = {0};
varSD(cellfun(@isempty, varSD)) = {0};
n = numel(varargin);

% Function values
value = func(var{:});

% Symbolic functions
vars = symvar(sym(func), n);
varSEs = sym('se', [1, n]);
varSDs = sym('sd', [1, n]);
funcs = symfun(sym(func), vars(:));

% Find SE & SD functions
sumSE = symfun(0, varSEs);
sumSD = symfun(0, varSDs);
for idx = 1: n
	dif = diff(funcs, vars(idx));
	sumSE = sumSE + (dif(var{:}) * varSEs(idx))^2;
	sumSD = sumSD + (dif(var{:}) * varSDs(idx))^2;
end

funcSE = sqrt(sumSE);
funcSD = sqrt(sumSD);
SE = double(funcSE(varSE{:}));
SD = double(funcSD(varSD{:}));
output = estm(value, 'SE', SE, 'SD', SD);

end