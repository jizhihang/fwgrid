function ncaDriver(parameters, folds, jobNum, Outpath)

    scores  = zeros(length(folds),1);
    native  = zeros(length(folds),1);
    T       = {};

    for f = 1:length(folds)

        T{f}        = nca_train(folds(f).Ktrain', folds(f).Ytrain);

        if ~isempty(folds(f).Kval)
            Perf        = mlr_test( T{f}.C, parameters.test_k,   ...
                                    folds(f).Ktrain,        ...
                                    folds(f).Ytrain,        ...
                                    folds(f).Kval,          ...
                                    folds(f).Yval);
        else
            Perf        = mlr_test( T{f}.C, parameters.test_k,   ...
                                    folds(f).Ktrain,        ...
                                    folds(f).Ytrain);
        end

        T{f}.test_k = Perf.KNNk;

        Perf        = mlr_test( T{f}.C, Perf.KNNk,      ...
                                [folds(f).Ktrain folds(f).Kval], ...
                                [folds(f).Ytrain; folds(f).Yval], ...
                                folds(f).Ktest,         ...
                                folds(f).Ytest);

        scores(f)   = Perf.KNN;

        % Compute the native results
        if ~isempty(folds(f).Kval)
            Perf        = mlr_test([], parameters.test_k, ...
                                    folds(f).Ktrain, folds(f).Ytrain, ...
                                    folds(f).Kval, folds(f).Yval);
        else
            Perf        = mlr_test([], parameters.test_k, ...
                                    folds(f).Ktrain, folds(f).Ytrain);
        end

        Perf        = mlr_test([], Perf.KNNk, ...
                                [folds(f).Ktrain folds(f).Kval], ...
                                [folds(f).Ytrain ; folds(f).Yval], ...
                                folds(f).Ktest, folds(f).Ytest);
        native(f)   = Perf.KNN;
    end

    experimentShowOutput(jobNum, parameters, scores, native);
    save(sprintf('%s/job%02d.mat', Outpath, jobNum), ...
            'parameters', 'scores', 'native', 'T');
end

