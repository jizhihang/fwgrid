function lmnnDriver(parameters, folds, jobNum, Outpath)

    scores  = zeros(length(folds), 1);
    native  = zeros(length(folds), 1);
    T       = {};

    for f = 1:length(folds)
        
        if ~isfield(folds(f), 'Kvalnorm')
            folds(f).Kvalnorm = [];
            folds(f).Ktestnorm = [];
        end

        % Validate over training neighborhood size

        bestScore   = -inf;
        bestTrainK  = 0;
        bestTestK   = 0;

        if ~isfield(folds(f), 'Kvalnorm')
            folds(f).Kvalnorm = [];
            folds(f).Ktestnorm = [];
        end


        for k = parameters.train_k
            [L, D]  = lmnn2(   folds(f).Ktrain,    ...
                                folds(f).Ytrain',   ...
                                k,                  ...
                                'quiet', 1);

            W = L' * L;
            D.pars.train_k = k;

            Perf        = mlr_test( W, parameters.test_k,   ...
                                    folds(f).Ktrain,        ...
                                    folds(f).Ytrain,        ...
                                    folds(f).Kval,          ...
                                    folds(f).Yval);

            if Perf.KNN > bestScore
                bestScore = Perf.KNN;
                bestTrainK = k;
                bestTestK = Perf.KNNk;
                T{f} = struct('W', W, 'D', D, 'test_k', bestTestK);
            end

            perfs{f}    = mlr_test( T{f}.W, T{f}.test_k,    ...
                                    [folds(f).Ktrain folds(f).Kval], ...
                                    [folds(f).Ytrain ; folds(f).Yval], ...
                                    folds(f).Ktest,         ...
                                    folds(f).Ytest);
            scores(f)   = perfs{f}.KNN;
            
            % Compute native scores using best validation k
            P           = mlr_test( [], parameters.test_k,   ...
                                    folds(f).Ktrain, folds(f).Ytrain,       ...
                                    folds(f).Kval, folds(f).Yval);
            P           = mlr_test( [], P.KNNk,   ...
                                    [folds(f).Ktrain folds(f).Kval], ...
                                    [folds(f).Ytrain ; folds(f).Yval], ...
                                    folds(f).Ktest, folds(f).Ytest);
            native(f)   = P.KNN;
        end

    end

    experimentShowOutput(jobNum, parameters, scores, native);
    save(sprintf('%s/job%02d.mat', Outpath, jobNum), ...
            'parameters', 'scores', 'native', 'T');
end

