function untitled(A, B)

    campiA = fieldnames(A);
    campiB = fieldnames(B);

    campiComuni = intersect(campiA, campiB);
    soloA = setdiff(campiA, campiB);
    soloB = setdiff(campiB, campiA);

    fprintf('--- Campi comuni ---\n');
    for i = 1:length(campiComuni)
        campo = campiComuni{i};
        
        valA = A.(campo);
        valB = B.(campo);

        if isequal(valA, valB)
            fprintf('✔ %s: UGUALI\n', campo);
        else
            fprintf('✘ %s: DIVERSI\n', campo);
            
            fprintf('   A.%s = ', campo);
            disp(valA);
            
            fprintf('   B.%s = ', campo);
            disp(valB);
        end
    end

    fprintf('\n--- Campi solo in A ---\n');
    disp(soloA);

    fprintf('\n--- Campi solo in B ---\n');
    disp(soloB);

end