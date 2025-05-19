function [out] = auto_shifting(arr)
    target = hex2dec('81');  % 0x81 in decimal
    idx = find(arr == target, 1);  % Find the first occurrence of 0x81
    if isempty(idx)
        out = arr;  % If 0x81 is not found, return the original array
        return;
    end
    % Calculate how much to shift to bring 0x81 to the penultimate position
    n = length(arr);
    shift_amount = mod((n - 1) - idx, n);  % Circular shift amount
    % Perform circular shift
    out = circshift(arr, [0, shift_amount]);
end
