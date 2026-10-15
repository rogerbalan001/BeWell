import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { ExpedienteModule } from '../expediente/expediente.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { FirmaDigitalService } from './application/firma-digital.service';
import { Kms } from './application/kms';
import { RecipesService } from './application/recipes.service';
import { RecipeRepository } from './domain/recipe-digital';
import { LlaveFirmaDoc, LlaveFirmaSchema, LocalKmsAdapter } from './infrastructure/local-kms.adapter';
import { MongoRecipeRepository } from './infrastructure/mongo-recipe.repository';
import { RecipeDoc, RecipeSchema } from './infrastructure/recipe.schema';
import { RecipesController } from './interface/recipes.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: RecipeDoc.name, schema: RecipeSchema },
      { name: LlaveFirmaDoc.name, schema: LlaveFirmaSchema },
    ]),
    CitasModule,
    MedicosModule,
    PerfilesModule,
    ExpedienteModule,
  ],
  controllers: [RecipesController],
  providers: [
    RecipesService,
    FirmaDigitalService,
    { provide: Kms, useClass: LocalKmsAdapter },
    { provide: RecipeRepository, useClass: MongoRecipeRepository },
  ],
})
export class RecipesModule {}
